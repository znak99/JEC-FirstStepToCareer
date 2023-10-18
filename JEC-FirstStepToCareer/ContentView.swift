//
//  ContentView.swift
//  JEC-FirstStepToCareer
//
//  Created by SeungWoo Hong on 2023/10/19.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
                .font(.custom(Font.customBold, size: 24))
            Text("就活一歩")
                .font(.custom(Font.customRegular, size: 36))
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
