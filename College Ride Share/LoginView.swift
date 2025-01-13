//
//  LoginView.swift
//  College Ride Share
//
//  Created by Quentin Adolphe on 12/10/24.
//

import SwiftUI
import StreamChat
import StreamChatSwiftUI

struct LoginView: View {
    let chatClient: ChatClient
    @State private var errorMessage: String?
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 20) {
            Text("Login with your .edu email")
                .font(.headline)

            Button(action: {
                            Task {
                                await DatabaseFunctions.shared.handleSignInButton(appState: appState, chatClient: chatClient)
                            }
                        }) {
                            Text("Sign in with Google")
                                .font(.title)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .padding()
    }
}

//#Preview {
//    LoginView()
//}
