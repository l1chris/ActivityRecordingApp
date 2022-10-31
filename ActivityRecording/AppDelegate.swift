/*

Abstract:
The app delegate class of the iOS app.
*/

import UIKit
import WatchConnectivity

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    // Session delegator
    private lazy var sessionDelegator: SessionDelegator = {
        return SessionDelegator()
    }()

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Configure and activate WCSession:
        
        assert(WCSession.isSupported(), "This App requires Watch Connectivity support!")
        
        // Assign delegate and activate
        WCSession.default.delegate = sessionDelegator
        WCSession.default.activate()
        
        return true
    }
}
