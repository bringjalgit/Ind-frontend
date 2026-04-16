import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:classifieds/data/cubit/Aadhaar/aadhaar_repo.dart';
import 'package:classifieds/data/cubit/Aadhaar/aadhaar_states.dart';
import 'package:classifieds/data/remote_data_source.dart';
import 'package:classifieds/model/AadhaarStatusModel.dart';

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
    final s = state;
    if (s is! AadhaarLoaded) return;
    if (!s.data.canSubmit) return; // can only upload in none|rejected

    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 2000,
    );
    if (picked == null) return;

    emit(AadhaarUploading(
      s.data,
      side,
      pendingFrontUrl: s.pendingFrontUrl,
      pendingBackUrl: s.pendingBackUrl,
    ));

    try {
      final result = await repo.uploadImage(side: side, localPath: picked.path);
      final fileUrl = result['file_url']!;
      emit(s.copyWith(
        pendingFrontUrl: side == 'front' ? fileUrl : s.pendingFrontUrl,
        pendingBackUrl: side == 'back' ? fileUrl : s.pendingBackUrl,
      ));
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
        'Upload failed. Please try again.',
        data: s.data,
        pendingFrontUrl: s.pendingFrontUrl,
        pendingBackUrl: s.pendingBackUrl,
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
