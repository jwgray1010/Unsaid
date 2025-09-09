import Flutter
import UIKit
import FirebaseCore

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configure Firebase
    FirebaseApp.configure()
    
    GeneratedPluginRegistrant.register(with: self)
    
    // Register our custom keyboard data sync bridge
    let registrar = self.registrar(forPlugin: "KeyboardDataSyncBridge")
    if let registrar = registrar {
      KeyboardDataSyncBridge.register(with: registrar)
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
