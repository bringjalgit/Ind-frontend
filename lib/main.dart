import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:app_links/app_links.dart';
import 'package:classifieds/services/NotificationService.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:classifieds/services/ApiClient.dart';
import 'package:classifieds/services/MetaEventTracker.dart';
import 'package:classifieds/services/SecureStorageService.dart';
import 'package:classifieds/state_injector.dart';
import 'package:classifieds/theme/AppTheme.dart';
import 'package:classifieds/utils/DeepLinkMapper.dart';
import 'package:classifieds/utils/NotificationIntent.dart';
import 'package:classifieds/utils/constants.dart';
import 'app_routes/router.dart';
import 'data/cubit/theme_cubit.dart';
import 'firebase_options.dart';
import 'package:classifieds/utils/AppLogger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ApiClient.setupInterceptors();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final storage = SecureStorageService.instance;
  final themeCubit = ThemeCubit(storage);
  await themeCubit.hydrate();

  await MetaEventTracker.initialize();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await NotificationService.instance.initialize();

  runApp(
    MultiRepositoryProvider(
      providers: StateInjector.repositoryProviders,
      child: MultiBlocProvider(
        providers: StateInjector.blocProviders(themeCubit),
        child: const MyApp(),
      ),
    ),
  );
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  debugPrint("📥 🔔 Background message received");
  debugPrint(message.toMap().toString());

  final notification = message.notification;
  final android = notification?.android;

  if (notification != null && android != null) {
    await NotificationService.instance.showNotification(
      notification,
      android,
      message.data,
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      MetaEventTracker.appOpen();
      debugPrint("📊 Meta Event Logged: app_open");
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, AppThemeMode>(
      builder: (context, appThemeMode) {
        final themeMode = switch (appThemeMode) {
          AppThemeMode.light => ThemeMode.light,
          AppThemeMode.dark => ThemeMode.dark,
          _ => ThemeMode.system,
        };
        return MaterialApp.router(
          title: 'IND Classifieds',
          theme: AppTheme.getLightTheme(),
          darkTheme: AppTheme.getDarkTheme(),
          themeMode: themeMode,
          debugShowCheckedModeBanner: false,
          routerConfig: appRouter,
        );
      },
    );
  }
}
