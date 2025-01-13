//
//  NextPage.swift
//  College Ride Share
//
//  Created by Quentin Adolphe on 12/2/24.
//
import SwiftUI

struct WhereToPage: View {
    let selectedDate: Date
    let onDestination: (Destination) -> Void
    
    
    var body: some View{
        NavigationStack{
            VStack(spacing:30){
                Text("Leaving at \(selectedDate)")
                    .font(.largeTitle)
                Text("Where would you like to go?")
                    .font(.title)
                
                Button(action: {
                    print("hell")
                    onDestination(.Swarthmore)
                    
                }) {
                    Text("to Swarthmore")
                        .font(.title)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    
                }
                
                Button(action: {
                    print("hi")
                    onDestination(.PHL)
                }) {
                    Text("to Philadelphia International Airport (PHL)")
                        .font(.title)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    
                }
            }
        }
    }
}


#Preview {
    ContentView()
}
