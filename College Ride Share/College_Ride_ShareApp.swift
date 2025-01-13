//
//  College_Ride_ShareApp.swift
//  College Ride Share
//
//  Created by Quentin Adolphe on 12/1/24.
//

import SwiftUI
import Firebase
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import GoogleSignIn
import StreamChat
import StreamChatSwiftUI


//extension ChatClient {
//    static var shared: ChatClient!
//}

class AppDelegate: NSObject, UIApplicationDelegate {    
    func application(
      _ app: UIApplication,
      open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
      var handled: Bool

      handled = GIDSignIn.sharedInstance.handle(url)
      if handled {
        return true
      }

      return false
    }
    
    func application(
      _ application: UIApplication,
      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if let error = error {
                        print("Failed to restore previous sign-in: \(error.localizedDescription)")
                        // Show signed-out state
                    } else if let user = user {
                        print("Successfully restored sign-in for user: \(user.profile?.email ?? "Unknown email")")
                        // Show signed-in state
                    }
      }

        return true
    }
    
}

@main
struct College_Ride_ShareApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var appState = AppState()
    
    var chatClient: ChatClient = {
        //For the tutorial we use a hard coded api key and application group identifier
        var config = ChatClientConfig(apiKey: .init("u3g2yupvs6bw"))
        config.isLocalStorageEnabled = true
        //config.applicationGroupIdentifier = "group.io.getstream.iOS.ChatDemoAppSwiftUI"

        // The resulting config is passed into a new `ChatClient` instance.
        let client = ChatClient(config: config)
        return client
    }()
    
    @State var streamChat: StreamChat?
        
    init() {
        streamChat = StreamChat(chatClient: chatClient)
    }
    
    var body: some Scene {
        WindowGroup {
            if appState.isLoggedIn {
                ContentView()
                    .environmentObject(appState)
            } else {
                LoginView(chatClient: chatClient)
                    .environmentObject(appState)
            }
            
        }
    }
}



//#Preview {
//    LoginView()
//}
