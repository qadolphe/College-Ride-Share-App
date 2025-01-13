//
//  MatchRidersView.swift
//  College Ride Share
//
//  Created by Quentin Adolphe on 12/30/24.
//

import SwiftUI

struct MatchRequest : Identifiable {
    let id: String
    let requesterUserIDs: [String]
    let requesterRideID: String
    let receiverUserIDs: [String]
    let receiverRideID: String
}

struct RequestRow: View {
    let request: MatchRequest
    @State private var requestNames: [String] = []
    
    var body: some View {
        VStack{
            Text("Request from: ")
                .font(.headline)
            Text(requestNames.joined(separator: ", "))
                .font(.subheadline)
                .padding(.bottom, 4)
        }
        .onAppear{
            requestNames = []
            for userID in request.requesterUserIDs {
                DatabaseFunctions.shared.getUserName(uid: userID) { userName in
                    if let userName = userName {
                        requestNames.append(userName)
                    }
                }
            }
        }
    }
}

struct RequestResponseView: View{
    let request: MatchRequest
    @State private var requestNames: [String] = []
    
    var body: some View {
        VStack{
            Text("Add riders to trip:")
                .font(.headline)
            ForEach(requestNames, id: \.self) { userName in
                Text("User name: \(userName)")
                    .font(.subheadline)
                    .padding(.bottom, 4)
            }
            HStack(spacing: 20) {
                Button(action: {
                    DatabaseFunctions.shared.matchRiders(rideID1: request.requesterRideID, rideID2: request.receiverRideID) { success in
                            if success {
                            } else {
                            }
                        }
                    DatabaseFunctions.shared.deleteMatchRequest(id: request.id) { success in
                            if success {
                            } else {
                            }
                        }
                }) {
                    Text("Accept")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Button(action: {
                    DatabaseFunctions.shared.deleteMatchRequest(id: request.id) { success in
                            if success {
                            } else {
                            }
                        }
                }) {
                    Text("Decline")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal)
        }
        .onAppear{
            requestNames = []
            for userID in request.requesterUserIDs {
                DatabaseFunctions.shared.getUserName(uid: userID) { userName in
                    if let userName = userName {
                        requestNames.append(userName)
                    }
                }
            }
        }
    }
}

struct MatchRidersView: View {
    let myRide: Ride
    let otherRide: Ride
    @State private var rides: [Ride] = []
    @State private var showConfirmRequest = false
    @State private var navigateHome = false
    @State private var potentialRiders: [String] = []

    var body: some View {
        NavigationStack{
            VStack(spacing: 20) {
                Text("Destination: \(otherRide.destination)")
                    .font(.headline)

                Text("Date (earliest between your rides): ")
                    .font(.headline)
                Text("\(min(otherRide.date, myRide.date))")
                    .font(.subheadline)
                    .padding(.bottom, 4)

                
                Text("Riders: ")
                    .font(.headline)
                Text(potentialRiders.joined(separator: ", "))
                    .font(.subheadline)
                    .padding(.bottom, 4)
                
                Text("Request Match?")
                    .font(.title)

                Button(action: {
                    showConfirmRequest = true
                }) {
                    Text("Send Request")
                        .font(.largeTitle)
                        .padding()
                        .background(Color.red.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Spacer()
            }
            .sheet(isPresented: $showConfirmRequest) {
                ConfirmationPageView(
                    message: "Confirm Request",
                     onConfirm: {
                         navigateHome = true
                         DatabaseFunctions.shared.sendMatchRequest(requesterUserIDs: myRide.userIDs, requesterRideID: myRide.id, receiverUserIDs: otherRide.userIDs, receiverRideID: otherRide.id) { success in
                                 if success {
                                     showConfirmRequest = false
                                     print("yay")
                                 } else {
                                     print("ohhhh")
                                 }
                             }
                     })
                 .presentationDetents([.fraction(0.3)])
            }
            .navigationDestination(isPresented: $navigateHome){
                ContentView()
                    .onAppear()
            }
            .onAppear {
                DatabaseFunctions.shared.getValidRides(date: otherRide.date) {fetchedRides, error in
                    if let error = error{
                        print("Error fetching rides: \(error.localizedDescription)")
                    } else if let fetchedRides = fetchedRides {
                        rides = fetchedRides
                    }
                        
                }
                potentialRiders = []
                for userID in otherRide.userIDs {
                    DatabaseFunctions.shared.getUserName(uid: userID) { userName in
                        if let userName = userName {
                            potentialRiders.append(userName)
                        }
                    }
                }
            }
        }
        .padding()
        .navigationTitle("Ride Details")
    }
}

