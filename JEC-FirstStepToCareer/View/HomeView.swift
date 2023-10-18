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
                            VStack {
                                ZStack {
                                    RoundedRectangle(cornerRadius: proxy.size.width / 20)
                                        .fill(.appPrimary)
                                        .offset(y: proxy.size.width / 20)
                                        .shadow(color: .appBlack.opacity(0.5), radius: 4)
                                    Rectangle()
                                        .fill(.appPrimary)
                                }
                                .frame(width: proxy.size.width)
                                .frame(height: proxy.size.height / 2.5 - proxy.size.width / 20)
                                .ignoresSafeArea()
                                
                                Spacer()
                            }
                            
                            // Contents
                            VStack {
                                // Logo + title and settings button
                                HStack {
                                    // Logo
                                    Image("AppLogo-White")
                                        .resizable()
                                        .frame(width: proxy.size.width / 12)
                                        .frame(height: proxy.size.width / 12)
                                    
                                    // Title
                                    Text("就活一歩")
                                        .font(.custom(Font.customSemiBold,
                                                      size: proxy.size.width / 20))
                                        .foregroundStyle(.appWhite)
                                    
                                    Spacer()
                                    
                                    // Settings button
                                    NavigationLink(destination: EmptyView()) {
                                        Image(systemName: "gearshape")
                                            .resizable()
                                            .frame(width: proxy.size.width / 20)
                                            .frame(height: proxy.size.width / 20)
                                            .foregroundStyle(.appWhite)
                                    }
                                    .padding(proxy.size.width / 48)
                                    .background {
                                        RoundedRectangle(cornerRadius: proxy.size.width / 32)
                                            .stroke(.appWhite, lineWidth: 1)
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding()
                        }
                        
                        // Body
                        VStack {
                            
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                })
                
                // Splash view
//                if !homeManager.isAppReady {
//                    SplashView()
//                }
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
