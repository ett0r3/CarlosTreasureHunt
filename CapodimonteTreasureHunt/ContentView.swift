//
//  ContentView.swift
//  CapodimonteTreasureHunt
//
//  Created by AFP FED 003 on 29/05/26.
//

import SwiftUI

struct ContentView: View {

    var body: some View {

        NavigationStack {

            ZStack {

                LinearGradient(
                    colors: [

                        Color(
                            red: 242 / 255,
                            green: 234 / 255,
                            blue: 249 / 255
                        ),

                        Color(
                            red: 206 / 255,
                            green: 189 / 255,
                            blue: 239 / 255
                        )
                    ],

                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()


                Image("home")
                    .resizable()
                    .scaledToFill()
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )
                    .clipped()
                    .ignoresSafeArea()


                NavigationLink(destination: SecondView()) {

                    ZStack {

                        Image("lens")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 350)
                            .offset(x: 13, y: 60)

                        Text("GIOCA")
                            .font(.system(size: 42))
                            .bold()
                            .foregroundStyle(Color.white)
                            .offset(x: -10, y: -20)
                        
                    }// END ZStack
                }
            }// END ZStack
        }
    }
}

#Preview {
    ContentView()
}
