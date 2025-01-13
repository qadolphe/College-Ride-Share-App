//
//  DatabaseFunctions.swift
//  College Ride Share
//
//  Created by Quentin Adolphe on 12/3/24.
//

import SwiftUI
import FirebaseFirestore
import Firebase
import GoogleSignIn
import FirebaseCore
import GoogleSignInSwift
import FirebaseAuth
import StreamChat
import StreamChatSwiftUI

final class DatabaseFunctions {
    static let shared = DatabaseFunctions()
    private let db = Firestore.firestore()
    private init() {}
    @State private var errorMessage: String?
    @StateObject private var appState = AppState()
    @Injected(\.chatClient) var chatClient
    
    func handleSignInButton(appState: AppState, chatClient: ChatClient) async {
        
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("ruh roh")
            return }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        do {
            let userAuthentication = try await GIDSignIn.sharedInstance.signIn(withPresenting: getRootViewController())
            let user = userAuthentication.user
            guard let idToken = user.idToken else {
                print("missing token")
                return
            }
            let accessToken = user.accessToken
            let credential = GoogleAuthProvider.credential(withIDToken: idToken.tokenString, accessToken:accessToken.tokenString)
            
            let result = try await Auth.auth().signIn(with: credential)
            let firebaseUser = result.user
            
            if result.additionalUserInfo?.isNewUser == true {
                let userData: [String: Any] = [
                    "id": firebaseUser.uid,
                    "name": firebaseUser.displayName ?? "Unknown",
                    "email": firebaseUser.email ?? "Unknown",
                    "createdAt": Timestamp(date: Date())
                ]

                try await db.collection("users").document(firebaseUser.uid).setData(userData)
                print("New user data added to Firestore")
            }
            
            connectUser(uid: firebaseUser.uid, username: firebaseUser.displayName ?? "Unknown")
            
            print("User \(firebaseUser.uid) signed in with email \(firebaseUser.email ?? "unknown")")
            
            appState.isLoggedIn = true
            print("isLoggedIn: \(appState.isLoggedIn)")
            return
        }
        catch {
            print(error.localizedDescription)
            errorMessage = error.localizedDescription
            return
        }
    }
    
    func handleSignOutButton(appState: AppState) {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            appState.isLoggedIn = false
            print("User signed out")
            print("isLoggedIn: \(appState.isLoggedIn)")
            return
        }
        catch {
            print(error.localizedDescription)
        }
    }
    
    func addRide(date: Date, destination: String, userIDs: [String]? = nil, completion: @escaping (Ride?, Bool) -> Void) {
        
        let riderIDs = userIDs ?? [getUserID()].compactMap { $0 }
        
        print(destination)
        let rideDoc = db.collection("rides").addDocument(data: [
                "userIDs": riderIDs,
                "date": Timestamp(date: date),
                "destination": destination,
                "carPoolScheduled": false
        ]) {error in
            if let error = error {
                completion(nil, false)
                return
            }
        }
        self.docToRide(document: rideDoc) { ride in
            if let ride = ride {
                completion(ride, true)
            } else {
                completion(nil, false)
            }
        }
        
    }
    
    func deleteRide(id: String, completion: @escaping (Bool) -> Void) {
        let ride = db.collection("rides").document(id)
        let userID = getUserID()
        
        ride.updateData([
            "userIDs": FieldValue.arrayRemove([userID])
        ]) { error in
            if let error = error {
                print("Error updating document: \(error.localizedDescription)")
            } else {
                print("Document successfully updated")
            }
        }
        
        ride.getDocument {document, error in
            if error != nil {
                completion(false)
            }
            if let document = document, document.exists {
                let data = document.data()
                if let userIDs = data?["userIDs"] as? [String], userIDs.isEmpty {
                    ride.delete() {error in
                        if error != nil {
                            completion(false)
                        } else {
                            completion(true)
                        }
                    }
                }
            }
        }
        
    }
    
    func sendMatchRequest(requesterUserIDs: [String], requesterRideID: String, receiverUserIDs: [String], receiverRideID: String, completion: @escaping (Bool) -> Void) {
        db.collection("matchRequests").addDocument(data: [
            "requesterUserIDs": requesterUserIDs,
            "requesterRideID": requesterRideID,
            "receiverUserIDs": receiverUserIDs,
            "receiverRideID": receiverRideID
        ]) {error in
            if let error = error {
                print("Error sending match request: \(error.localizedDescription)")
                completion(false)
            } else {
                print("Match request sent successfully.")
                completion(true)
            }
        }
    }
    
    func deleteMatchRequest(id: String, completion: @escaping (Bool) -> Void) {
        let request = db.collection("matchRequests").document(id)
        request.getDocument {document, error in
            if error != nil {
                completion(false)
            }
            if let document = document, document.exists {
                    request.delete() {error in
                        if error != nil {
                            completion(false)
                        } else {
                            completion(true)
                        }
                    }
            }
        }
    }
    
    func matchRiders(rideID1: String, rideID2: String, completion: @escaping (Bool) -> Void) {
        self.getRideFromID(rideID: rideID1) { ride1 in
            guard let ride1 = ride1 else {
                completion(false)
                return
            }
            self.getRideFromID(rideID: rideID2) { ride2 in
                guard let ride2 = ride2 else {
                    completion(false)
                    return
                }
                print(ride1.userIDs)
                print(ride2.userIDs)
                
                let newDate = min(ride1.date, ride2.date)
                let userIDs = ride1.userIDs + ride2.userIDs
                self.addRide(date: newDate, destination: ride1.destination, userIDs: userIDs) { ride, success in
                     if !success {
                         print("Failed to add ride.")
                         completion(false)
                     } else {
                         print("Ride added successfully.")
                         self.deleteRide(id: ride1.id) { success in
                                 if !success {
                                     print("ohhhh")
                                     completion(false)
                                     
                                 } else {
                                     print("yay")
                                     self.deleteRide(id: ride2.id) { success in
                                             if !success {
                                                 print("ohhhh")
                                                 completion(false)
                                             } else {
                                                 print("yay")
                                                 self.createChannel(userIDs: userIDs) {error in
                                                     if error != nil {
                                                         completion(false)
                                                     } else {
                                                         completion(true)
                                                     }
                                                 }
                                             }
                                         }
                                 }
                             }
                     }
                 }
            }
        }
    }
    
//    func getRelevantRides(date: Date) async throws -> [Ride] {
//        let snapshot = try await db.collection("rides")
//            .whereField("date", isLessThanOrEqualTo: Timestamp(date: date))
//        //.whereField("userIDs", isNotEqualTo: userID)
//            .getDocuments()
//        
//        let documents = snapshot.documents
//        var fetchedRides: [Ride] = []
//        
//        for document in documents {
//            let docRef = db.collection("rides").document(document.documentID)
//            try await self.docToRide(document: docRef) {ride in
//                    fetchedRides.append(ride)
//                } else {
//                    print("errororor")
//                }
//        }
//        return fetchedRides
//    }
    func getMatchRequests(myRideID: String, completion: @escaping ([MatchRequest]?, Error?) -> Void) {
        db.collection("matchRequests")
            .whereField("receiverRideID", isEqualTo: myRideID)
            .getDocuments { snapshot, error in
            if let error = error {
                completion(nil, error)
                return
            }
             
                let requests = snapshot?.documents.compactMap { document -> MatchRequest? in
                    return  self.dbToMatchRequest(document: document)
                }
            completion(requests, nil)
        }
    }
    
    func getValidRides(date: Date, completion: @escaping ([Ride]?, Error?) -> Void) {
        guard let firebaseUser = Auth.auth().currentUser else {
            print("No authenticated user.")
            return
        }
        let userID = firebaseUser.uid
        
        db.collection("rides")
            .whereField("date", isLessThanOrEqualTo: Timestamp(date: date))
            //.whereField("userIDs", isNotEqualTo: userID)
            .getDocuments { snapshot, error in
            if let error = error {
                completion(nil, error)
                return
            }
             
                let rides = snapshot?.documents.compactMap { document -> Ride? in
                    return  self.dbToRide(document: document)
                }
            completion(rides, nil)
        }
    }
    
    func getMyRides(completion: @escaping ([Ride]?, Error?) -> Void) {
        guard let firebaseUser = Auth.auth().currentUser else {
            print("No authenticated user.")
            return
        }
        let userID = firebaseUser.uid
        
        db.collection("rides")
            .whereField("userIDs", arrayContains: userID)
            .getDocuments { snapshot, error in
            if let error = error {
                completion(nil, error)
                return
            }
             
                let rides = snapshot?.documents.compactMap { document -> Ride? in
                    return  self.dbToRide(document: document)
                    
                }
            completion(rides, nil)
        }
    }

    func fetchRides(completion: @escaping ([Ride]?, Error?) -> Void) {
        db.collection("rides").getDocuments { snapshot, error in
            if let error = error {
                completion(nil, error)
                return
            }
            let rides = snapshot?.documents.compactMap { document -> Ride? in
                return  self.dbToRide(document: document)
            }
            completion(rides, nil)
        }
    }
    
    func getUserName(uid: String, completion: @escaping (String?) -> Void) {
        db.collection("users")
            .document(uid) // Access document directly by user ID
            .getDocument { document, error in
                if let error = error {
                    print("Error fetching user: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                if let document = document, document.exists, let name = document.data()?["name"] as? String {
                    completion(name)
                } else {
                    completion(nil)
                }
            }
    }
    
    private func connectUser(uid: String, username: String) {
        chatClient.connectUser(
            userInfo: .init(id: uid, name: username),
            token: Token.development(userId: uid) // Developer token
        ) { error in
            if let error = error {
                print("Error connecting user: \(error)")
                return
            }
            
            print("User connected successfully.")
        }
    }
    
    private func createChannel(userIDs: [String], completion: @escaping (Error?) -> Void) {
        let id = userIDs.joined(separator: "_")
        let channelId = ChannelId(type: .messaging, id: id)
        let channelController = chatClient.channelController(for: channelId)
        channelController.synchronize { error in
            if let error = error {
                print("Error creating channel: \(error)")
                completion(error)
            } else {
                print("Channel created successfully.")
                completion(nil)
            }
        }
    }

    private func getRideFromID(rideID: String, completion: @escaping (Ride?) -> Void) {
        db.collection("rides")
            .document(rideID)
            .getDocument { snapshot, error in
                if let error = error {
                    print("Error fetching ride: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                guard let snapshot = snapshot, snapshot.exists else {
                    print("No document found for rideID: \(rideID)")
                    completion(nil)
                    return
                }
                
                self.docToRide(document: snapshot.reference) { ride in
                    if let ride = ride {
                        completion(ride)
                    } else {
                        completion(nil)
                    }
                }
                
            }
    }
    
    private func getRiders(rideID: String, completion: @escaping ([String]?, Bool) -> Void) {
        db.collection("rides").document(rideID).getDocument {snapshot, error in
            if let error = error {
                print("Error fetching ride: \(error)")
                completion(nil, false)
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists else {
                print("Ride with ID \(rideID) not found.")
                completion(nil, false)
                return
            }
            
            if let userIDs = snapshot.data()?["userIDs"] as? [String] {
                completion(userIDs, true)
            } else {
                print("No riders found for ride \(rideID).")
                completion(nil, false)
            }
        }
    }
    
    private func dbToRide(document: QueryDocumentSnapshot) -> Ride? {
        let data = document.data()
        guard
            let date = (data["date"] as? Timestamp)?.dateValue(),
            let carPoolScheduled = data["carPoolScheduled"] as? Bool,
            let userIDs = data["userIDs"] as? [String],
            let destination = data["destination"] as? String else {
            return nil
            
        }
                
        return Ride(id: document.documentID, date: date, destination: destination, carPoolScheduled: carPoolScheduled, userIDs: userIDs)
    }
    
    private func dbToMatchRequest(document: QueryDocumentSnapshot) -> MatchRequest? {
        let data = document.data()
        guard
            let requesterUserIDs = data["requesterUserIDs"] as? [String],
            let requesterRideID = data["requesterRideID"] as? String,
            let receiverUserIDs = data["receiverUserIDs"] as? [String],
            let receiverRideID = data["receiverRideID"] as? String else {
            return nil
        }
                
        return MatchRequest(id: document.documentID, requesterUserIDs: requesterUserIDs, requesterRideID: requesterRideID, receiverUserIDs: receiverUserIDs, receiverRideID: receiverRideID)
    }

    private func docToRide(document: DocumentReference, completion: @escaping (Ride?) -> Void) {
        document.getDocument {snapshot, error in
            if let error = error {
                print("Error fetching document: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            
            guard let snapshot = snapshot,
                  let data = snapshot.data(),
                  let date = (data["date"] as? Timestamp)?.dateValue(),
                  let carPoolScheduled = data["carPoolScheduled"] as? Bool,
                  let userIDs = data["userIDs"] as? [String],
                  let destination = data["destination"] as? String else {
                completion(nil)
                return
            }
            
            completion( Ride(id: snapshot.documentID, date: date, destination: destination, carPoolScheduled: carPoolScheduled, userIDs: userIDs))
            return
        }
    }
    
    private func getUserID() -> String? {
        guard let firebaseUser = Auth.auth().currentUser else {
            print("No authenticated user.")
            return nil
        }
        return firebaseUser.uid
    }
    
    private func getRootViewController() -> UIViewController {
        guard let screen = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            fatalError("No active scene.")
        }
        guard let root = screen.windows.first?.rootViewController else {
            fatalError("No root view controller.")
        }
        return root
    }

}
