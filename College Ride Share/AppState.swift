//
//  AppState.swift
//  College Ride Share
//
//  Created by Quentin Adolphe on 12/26/24.
//

import Combine
import GoogleSignIn
import FirebaseCore
import GoogleSignInSwift
import FirebaseAuth

class AppState : ObservableObject {
    @Published var isLoggedIn: Bool  {
        didSet {
            UserDefaults.standard.set(isLoggedIn, forKey: "isLoggedIn")
        }
    }
    
    init () {
        if let user = GIDSignIn.sharedInstance.currentUser {
            print("found")
            isLoggedIn = true
        } else {
            isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
            print("not found")
        }

    }
}
