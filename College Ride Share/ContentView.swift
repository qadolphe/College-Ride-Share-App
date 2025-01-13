//
//  ContentView.swift
//  College Ride Share
//
//  Created by Quentin Adolphe on 12/1/24.
//

import SwiftUI
import StreamChat
import StreamChatSwiftUI

enum Destination: String, Identifiable {
    var id: String {rawValue}
    
    case Swarthmore = "Swarthmore"
    case PHL = "PHL"
}

struct ContentView: View {
    @State private var showDatePicker = false
    @State private var selectedDestination: Destination? = nil
    @State private var navigateToNextPage = false
    @State private var selectedDate: Date = Date()
    @State private var showConfirmationMessage = false
    @State private var goToRideDetail = false
    @State private var rides: [Ride] = []
    @State private var recentRide: Ride? = nil
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack{
            VStack {
                Button(action: {showDatePicker.toggle()
                }) {
                    Text("Schedule Trip")
                        .font(.largeTitle)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    
                }
                .sheet(isPresented: $showDatePicker) {
                    DatePickerSheet(
                        selectedDate: $selectedDate,
                        onNext: {
                            showDatePicker = false
                            navigateToNextPage = true
                        }
                        )
                    .presentationDetents([.fraction(0.65)])
                }
            }
            Text("Leave Soon:")
                .font(.title)
                .padding()

            Button(action: {
                selectedDestination = .Swarthmore
                selectedDate = Date()
            }) {
                Text("to Swarthmore")
                    .font(.title)
                    .padding()
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                
            }
            
            Button(action: {
                selectedDestination = .PHL
                selectedDate = Date()
            }) {
                Text("to Philadelphia International Airport (PHL)")
                    .font(.title)
                    .padding()
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                
            }
            
            Text("Your Rides:")
                .font(.title)
                .padding()
            Group {
                if rides.isEmpty {
                    Text("No rides scheduled.")
                        .font(.headline)
                        .padding()
                } else {
                    List(rides) { ride in
                        NavigationLink(destination: RideDetailView(ride: ride)) {
                            RideRow(ride: ride)
                        }
                    }
                }
            }
            
            
            Button(action: {
                DatabaseFunctions.shared.handleSignOutButton(appState: appState)
            }) {
                Text("Logout")
                    .font(.title)
                    .padding()
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                
            }
            .onAppear {
                DatabaseFunctions.shared.getMyRides {fetchedRides, error in
                    if let error = error{
                        print("Error fetching rides: \(error.localizedDescription)")
                    } else if let fetchedRides = fetchedRides {
                        rides = fetchedRides
                    }
                        
                }
            }

            
            .padding()
            .navigationDestination(
                 isPresented: $navigateToNextPage) {
                     WhereToPage(selectedDate: selectedDate,
                         onDestination: {destination in
                         selectedDestination = destination
                         printStateVariables()
                     })
            }
            .navigationDestination(
                 isPresented: $goToRideDetail){
                     if let ride = recentRide {
                         RideDetailView(ride: ride)
                     }
                 }
            .sheet(item: $selectedDestination) {destination in
                ConfirmationPageView(
                    message: "Confirm Carpool",
                     onConfirm: {
                        DatabaseFunctions.shared.addRide(date: selectedDate, destination: destination.rawValue) { ride, success in
                             if success {
                                 recentRide = ride
                                 navigateToNextPage = false
                                 showConfirmationMessage = true
                                 selectedDestination = nil
                                 goToRideDetail = true
                                 print("Ride added successfully.")
                             } else {
                                 print("Failed to add ride.")
                             }
                         }
                     })
                 .presentationDetents([.fraction(0.3)])
            }
        }
        .overlay(
                   Group {
                       if showConfirmationMessage {
                           Text("Ride Scheduled!")
                               .font(.headline)
                               .padding()
                               .background(Color.green.opacity(0.8))
                               .cornerRadius(10)
                               .foregroundColor(.white)
                               .transition(.opacity)
                               .zIndex(1)
//                       } else if showError {
//                           Text("Failed to Add Ride. Try Again.")
//                               .font(.headline)
//                               .padding()
//                               .background(Color.red.opacity(0.8))
//                               .cornerRadius(10)
//                               .foregroundColor(.white)
//                               .transition(.opacity)
//                               .zIndex(1)
                       }
                })
        .onChange(of: showConfirmationMessage) {oldValue, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showConfirmationMessage = false
                }
            }}
    }
    
    private func printStateVariables() {
        print("showDatePicker: \(showDatePicker)")
        print("selectedDestination: \(String(describing: selectedDestination))")
        print("navigateToNextPage: \(navigateToNextPage)")
        print("selectedDate: \(selectedDate)")
        print("showConfirmationMessage: \(showConfirmationMessage)")
        print("goToRideDetail: \(goToRideDetail)")
        print("rides: \(rides)")
        print("recentRide: \(String(describing: recentRide))")
    }
}

#Preview {
    var chatClient: ChatClient = {
        //For the tutorial we use a hard coded api key and application group identifier
        var config = ChatClientConfig(apiKey: .init("8br4watad788"))
        config.isLocalStorageEnabled = true
        config.applicationGroupIdentifier = "group.io.getstream.iOS.ChatDemoAppSwiftUI"

        // The resulting config is passed into a new `ChatClient` instance.
        let client = ChatClient(config: config)
        return client
    }()
    ContentView()
}
