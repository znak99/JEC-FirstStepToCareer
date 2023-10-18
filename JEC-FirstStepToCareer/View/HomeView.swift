//
//  HomeView.swift
//  JEC-FirstStepToCareer
//
//  Created by SeungWoo Hong on 2023/10/19.
//

import SwiftUI

struct HomeView: View {
    
    @StateObject var homeManager = HomeManager()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.appWhite.ignoresSafeArea()
                
                // Splash view
                if !homeManager.isAppReady {
                    SplashView()
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    homeManager.isAppReady.toggle()
                }
            }
        }
    }
}

#Preview {
    HomeView()
}
