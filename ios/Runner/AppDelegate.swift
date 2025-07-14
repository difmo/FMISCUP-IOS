import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController

    // alarm_channel
    let alarmChannel = FlutterMethodChannel(name: "alarm_channel", binaryMessenger: controller.binaryMessenger)
    alarmChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "setAlarms":
        print("setAlarms called on iOS")
        result("Alarm set (stub) on iOS")
      case "requestExactAlarmPermission":
        print("requestExactAlarmPermission called on iOS")
        result("Not required on iOS")
      case "cancelAlarms":
        print("cancelAlarms called on iOS")
        result("Alarms canceled (stub) on iOS")
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    // com.techwings.fmiscup (used in FloodManagementSplashScreen)
    let devModeChannel = FlutterMethodChannel(name: "com.techwings.fmiscup", binaryMessenger: controller.binaryMessenger)
    devModeChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "isDeveloperModeEnabled" {
        print("isDeveloperModeEnabled called on iOS")
        result(false) // Always false on iOS
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
