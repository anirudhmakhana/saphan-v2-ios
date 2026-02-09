import UIKit
import SaphanCore

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        Logger.shared.log("App launched", category: .app, level: .info)

        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        Logger.shared.log("App will terminate", category: .app, level: .info)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        Logger.shared.log("App became active", category: .app, level: .debug)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        Logger.shared.log("App will resign active", category: .app, level: .debug)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        Logger.shared.log("App entered background", category: .app, level: .debug)
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        Logger.shared.log("App will enter foreground", category: .app, level: .debug)
    }
}
