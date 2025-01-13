//
//  ScheduleTripView.swift
//  College Ride Share
//
//  Created by Quentin Adolphe on 12/2/24.
//
import SwiftUI

struct ConfirmationPageView: View {
    let message: String
//    let destination: String
    let onConfirm: () -> Void

    @State private var showError = false

    
    var body: some View {
        
        NavigationStack{
            VStack(spacing:15) {
                Text(message)
                    .font(.largeTitle)
                    .padding()
                

                
                Button(action: {
                    onConfirm()
                }) {
                    Text("Confirm")
                        .font(.largeTitle)
                        .padding()
                        .background(Color.red.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    
                }
                
                Spacer()
            }
        }
    }
}
