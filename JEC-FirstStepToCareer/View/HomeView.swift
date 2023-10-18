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
                
                // Contents
                GeometryReader(content: { proxy in
                    VStack {
                        // Header
                        ZStack {
                            // Background
                            Group {
                                Rectangle()
                                    .fill(.appPrimary)
                                RoundedRectangle(cornerRadius: proxy.size.width / 20)
                                    .fill(.appPrimary)
                                    .offset(y: proxy.size.width / 20)
                            }
                            .frame(width: proxy.size.width)
                            .frame(height: proxy.size.height / 2.5 - proxy.size.width / 20)
                            .ignoresSafeArea()
                            
                            // Contents
                            VStack {
                                
                            }
                        }
                        
                        // Body
                        VStack {
                            
                        }
                        
                        Spacer()
                    }
                })
                
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
