//
//  RideDetailView.swift
//  College Ride Share
//
//  Created by Quentin Adolphe on 12/28/24.
//
import SwiftUI

struct RideDetailView: View {
    let ride: Ride
    @State private var rides: [Ride] = []
    @State private var matchRequests: [MatchRequest] = []
    @State private var showConfirmDelete = false
    @State private var navigateHome = false
    @State private var riderNames: [String] = []
    @State private var showChat = false

    var body: some View {
        NavigationStack{
            VStack(spacing: 20) {
                Text("Trip to \(ride.destination)")
                    .font(.largeTitle)
                    .padding()

                Text("Date:")
                    .font(.headline)
                Text("\(ride.date)")
                    .font(.subheadline)
                    .padding(.bottom, 4)
                
                Text("Current Riders: ")
                    .font(.headline)
                Text(riderNames.joined(separator: ", "))
                    .font(.subheadline)
                    .padding(.bottom, 4)
                
                if ride.userIDs.count > 1 {
                    Button(action: {
                        showChat = true
                    }) {
                        Text("Open Chat")
                            .font(.title)
                            .padding()
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                
                Text(
                    "Match Requests:"
                )
                    .font(.title)
                Group {
                    if matchRequests.isEmpty {
                        Text("No requests.")
                            .font(.headline)
                            .padding()
                    } else {List(matchRequests) { request in
                        NavigationLink(destination: RequestResponseView(request: request)) {
                            RequestRow(request: request)
                        }
                    }
                        
                    }
                }
                Text("Rides scheduled near yours:")
                    .font(.title)
                Group {
                    if rides.isEmpty {
                        Text("No rides scheduled.")
                            .font(.headline)
                            .padding()
                    } else {List(rides) { rideInList in
                        NavigationLink(destination: MatchRidersView(myRide: ride, otherRide: rideInList)) {
                            RideRow(ride: rideInList)
                        }
                    }
                        
                    }
                }
                Button(action: {
                    showConfirmDelete = true
                }) {
                    Text("Cancel my ride")
                        .font(.largeTitle)
                        .padding()
                        .background(Color.red.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Spacer()
            }
            .sheet(isPresented: $showConfirmDelete) {
                ConfirmationPageView(
                    message: "Confirm Cancellation",
                     onConfirm: {
                         navigateHome = true
                         DatabaseFunctions.shared.deleteRide(id: ride.id) { success in
                                 if success {
                                     showConfirmDelete = false
                                     print("yay")
                                 } else {
                                     print("ohhhh")
                                 }
                             }
                     })
                 .presentationDetents([.fraction(0.3)])
            }
            .navigationDestination(
                isPresented: $showChat) {
                    ChatView(userIDs: ride.userIDs)
            }
            .navigationDestination(isPresented: $navigateHome){
                ContentView()
            }
            .onAppear {
                riderNames = []
                for userID in ride.userIDs {
                    DatabaseFunctions.shared.getUserName(uid: userID) { userName in
                        if let userName = userName {
                            riderNames.append(userName)
                        }
                    }
                }
                DatabaseFunctions.shared.getValidRides(date: ride.date) {fetchedRides, error in
                    if let error = error{
                        print("Error fetching rides: \(error.localizedDescription)")
                    } else if let fetchedRides = fetchedRides {
                        rides = fetchedRides
                    }
                        
                }
                DatabaseFunctions.shared.getMatchRequests(myRideID: ride.id) {fetchedRequests, error in
                    if let error = error{
                        print("Error fetching requests: \(error.localizedDescription)")
                    } else if let fetchedRequests = fetchedRequests {
                        matchRequests = fetchedRequests
                    }
                        
                }
            }
        }
        .padding()
        .navigationTitle("Ride Details")
    }
}

#Preview {
    RideDetailView(ride: Ride(id: "", date: Date(), destination: "", carPoolScheduled: false, userIDs: ["asdas"]))
}
