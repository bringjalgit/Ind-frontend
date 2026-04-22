import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:classifieds/data/cubit/Aadhaar/aadhaar_repo.dart';
import 'package:classifieds/data/cubit/Aadhaar/aadhaar_states.dart';
import 'package:classifieds/data/remote_data_source.dart';
import 'package:classifieds/model/AadhaarStatusModel.dart';
import 'package:classifieds/utils/ImageUtils.dart';

/// Cubit for the Aadhaar verification flow.
///
/// Responsibilities (in order):
///   1. Load current status on screen entry.
///   2. Pick an image (camera or gallery) for front or back, upload
///      directly to S3, and hold the returned file_url locally.
///   3. Once BOTH urls are held, commit via U2 (submit) — backend
///      atomically transitions none|rejected → pending.
///   4. Re-fetch status after submit so the UI pivots to the "pending"
///      waiting card.
///
/// Design choices:
///   - Uploads stream through AadhaarUploading so the button shows a
///     spinner on the side being uploaded — only ONE side at a time.
///   - Local URLs are discarded on failure so the user can retry cleanly.
///   - Backend is the source of truth for state; we never optimistically
///     flip `status` to 'pending' before U2 succeeds.
class AadhaarCubit extends Cubit<AadhaarState> {
  final AadhaarRepo repo;
  final ImagePicker _picker = ImagePicker();

  AadhaarCubit(this.repo) : super(const AadhaarInitial());

  Future<void> loadStatus() async {
    emit(const AadhaarLoading());
    try {
      final res = await repo.getStatus();
      final data = res?.data ?? AadhaarStatusData();
      emit(AadhaarLoaded(data));
    } on AadhaarException catch (e) {
      emit(AadhaarFailure(e.message, code: e.code));
    } catch (e) {
      emit(AadhaarFailure('Unable to load status. Check your connection.'));
    }
  }

  /// Drops any locally-held front/back URLs without clearing server
  /// state. Called e.g. when the user navigates away and comes back,
  /// or after a failed submit that we want to reset.
  void clearLocalHolds() {
    final s = state;
    if (s is AadhaarLoaded) {
      emit(AadhaarLoaded(s.data));
    }
  }

  Future<void> pickAndUpload({
    required String side, // 'front' | 'back'
    required ImageSource source,
  }) async {
    // M17 — accept entry from AadhaarLoaded OR AadhaarFailure (with data).
    // Previously a failed upload parked the cubit in AadhaarFailure, and
    // the early-return here meant the user had to leave + return to retry.
    final entryState = state;
    final AadhaarStatusData baseData;
    String? initialFrontUrl;
    String? initialBackUrl;
    if (entryState is AadhaarLoaded) {
      baseData = entryState.data;
      initialFrontUrl = entryState.pendingFrontUrl;
      initialBackUrl = entryState.pendingBackUrl;
    } else if (entryState is AadhaarFailure && entryState.data != null) {
      baseData = entryState.data!;
      initialFrontUrl = entryState.pendingFrontUrl;
      initialBackUrl = entryState.pendingBackUrl;
    } else {
      return;
    }

    // Guard against double-entry while an upload is in flight.
    if (state is AadhaarUploading || state is AadhaarSubmitting) return;
    if (!baseData.canSubmit) return; // only none|rejected can upload

    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 2000,
    );
    if (picked == null) return;

    // M15 — compress locally before reading bytes + S3 PUT. A raw 12MP
    // Aadhaar scan can exceed 5MB; compression brings it into a range
    // that survives slow networks and doesn't OOM low-RAM Android.
    File toUpload = File(picked.path);
    try {
      final compressed = await ImageUtils.compressImage(toUpload);
      if (compressed != null) toUpload = compressed;
    } catch (_) {
      // Non-fatal — fall through with the original file.
    }

    emit(AadhaarUploading(
      baseData,
      side,
      pendingFrontUrl: initialFrontUrl,
      pendingBackUrl: initialBackUrl,
    ));

    try {
      final result = await repo.uploadImage(side: side, localPath: toUpload.path);
      final fileUrl = result['file_url']!;
      // H7 — re-read state at emit time instead of using the captured
      // `entryState` snapshot. If the other side completed during this
      // call's async pick+upload window, its URL is already in state
      // and we must merge against that, not the stale snapshot.
      final now = state;
      AadhaarStatusData currentData = baseData;
      String? currentFront;
      String? currentBack;
      if (now is AadhaarLoaded) {
        currentData = now.data;
        currentFront = now.pendingFrontUrl;
        currentBack = now.pendingBackUrl;
      } else if (now is AadhaarUploading) {
        currentData = now.data;
        currentFront = now.pendingFrontUrl;
        currentBack = now.pendingBackUrl;
      } else if (now is AadhaarFailure && now.data != null) {
        currentData = now.data!;
        currentFront = now.pendingFrontUrl;
        currentBack = now.pendingBackUrl;
      }
      emit(AadhaarLoaded(
        currentData,
        pendingFrontUrl: side == 'front' ? fileUrl : currentFront,
        pendingBackUrl: side == 'back' ? fileUrl : currentBack,
      ));
    } on AadhaarException catch (e) {
      emit(AadhaarFailure(
        e.message,
        code: e.code,
        data: baseData,
        pendingFrontUrl: initialFrontUrl,
        pendingBackUrl: initialBackUrl,
      ));
    } catch (_) {
      emit(AadhaarFailure(
        'Upload failed. Please try again.',
        data: baseData,
        pendingFrontUrl: initialFrontUrl,
        pendingBackUrl: initialBackUrl,
      ));
    }
  }

  Future<void> submit() async {
    final s = state;
    if (s is! AadhaarLoaded) return;
    if (!s.canSubmit) return;

    emit(AadhaarSubmitting(s.data));
    try {
      await repo.submit(
        frontUrl: s.pendingFrontUrl!,
        backUrl: s.pendingBackUrl!,
      );
      // Re-fetch authoritative state instead of trusting the submit
      // response — backend is the single source of truth.
      await loadStatus();
    } on AadhaarException catch (e) {
      emit(AadhaarFailure(
        e.message,
        code: e.code,
        data: s.data,
        pendingFrontUrl: s.pendingFrontUrl,
        pendingBackUrl: s.pendingBackUrl,
      ));
    } catch (_) {
      emit(AadhaarFailure(
        'Submission failed. Please try again.',
        data: s.data,
        pendingFrontUrl: s.pendingFrontUrl,
        pendingBackUrl: s.pendingBackUrl,
      ));
    }
  }

  /// Called from the Failure → Retry button. Re-emits a Loaded so the
  /// screen can rehydrate from the last-known data plus pending holds.
  void dismissError() {
    final s = state;
    if (s is AadhaarFailure && s.data != null) {
      emit(AadhaarLoaded(
        s.data!,
        pendingFrontUrl: s.pendingFrontUrl,
        pendingBackUrl: s.pendingBackUrl,
      ));
    } else {
      loadStatus();
    }
  }
}
