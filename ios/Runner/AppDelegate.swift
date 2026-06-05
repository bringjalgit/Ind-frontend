import UIKit
import Flutter
import FirebaseCore
import UserNotifications
import GoogleMaps
import FBSDKCoreKit
import AppTrackingTransparency
import AdSupport

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)

    Settings.shared.isAutoLogAppEventsEnabled = true
    Settings.shared.isCodelessDebugLogEnabled = true

    // ✅ Request Tracking Authorization
    if #available(iOS 14, *) {
      ATTrackingManager.requestTrackingAuthorization { status in
        switch status {
        case .authorized:
          Settings.shared.isAdvertiserTrackingEnabled = true
          AppEvents.shared.activateApp()
        default:
          Settings.shared.isAdvertiserTrackingEnabled = false
        }
      }
    } else {
      Settings.shared.isAdvertiserTrackingEnabled = true
      AppEvents.shared.activateApp()
    }

    FirebaseApp.configure()
    GMSServices.provideAPIKey("AIzaSyD0-eauuJ1zBrknaL4uNexkR21cYVOkj7k")
    GeneratedPluginRegistrant.register(with: self)

    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
      if granted { DispatchQueue.main.async { application.registerForRemoteNotifications() } }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    ApplicationDelegate.shared.application(app, open: url, options: options)
    return true
  }
}

