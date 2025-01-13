//
//  DatePickerSheet.swift
//  College Ride Share
//
//  Created by Quentin Adolphe on 12/2/24.
//
import SwiftUI

struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    let onNext: () -> Void
    
    var body: some View{
        NavigationStack{
            VStack(spacing:30){
                
                
                Text("When would you like to leave?")
                    .font(.title)
                    .padding(.horizontal)
                
                DatePickerView(selectedDate: $selectedDate)
                    .frame(height: 150)
                
                Button(action: {onNext()
                }) {
                        Text("Next")
                        .font(.largeTitle)
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
