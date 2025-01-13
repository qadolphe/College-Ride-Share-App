//
//  AllRides.swift
//  College Ride Share
//
//  Created by Quentin Adolphe on 12/4/24.
//

import SwiftUI
import FirebaseFirestore


struct Ride: Identifiable {
    let id: String
    let date: Date
    let destination: String
    let carPoolScheduled : Bool
    let userIDs: [String]
}

struct RideRow: View {
    let ride: Ride
    
    var body: some View {
        VStack{
            Text(ride.destination)
                .font(.headline)
            Text("Date: \(ride.date)")
        }
    }
}

struct AllRidesView : View {
    @State private var rides: [Ride] = []
    
    var body: some View {
        NavigationStack {
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
            .navigationTitle("Scheduled Rides")
            .onAppear {
                DatabaseFunctions.shared.fetchRides {fetchedRides, error in
                    if let error = error{
                        print("Error fetching rides: \(error.localizedDescription)")
                    } else if let fetchedRides = fetchedRides {
                        rides = fetchedRides
                    }
                        
                }
            }
        }
    }
    
}

struct RelevantRidesView : View {
    @State private var rides: [Ride] = []
    let  selectedDate: Date
    
    var body: some View {
        NavigationStack {
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
            .navigationTitle("Rides similar to you")
            .onAppear {
                DatabaseFunctions.shared.getValidRides(date: selectedDate) {fetchedRides, error in
                    if let error = error{
                        print("Error fetching rides: \(error.localizedDescription)")
                    } else if let fetchedRides = fetchedRides {
                        rides = fetchedRides
                    }
                        
                }
            }
        }
    }
    
}


#Preview {
    AllRidesView()
}
