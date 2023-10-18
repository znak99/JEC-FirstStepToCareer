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
                        if !homeManager.isFieldFocused {
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
                                
                                // Background text
                                Group {
                                    Text(homeManager.bgText)
                                        .font(.custom(Font.customBlack, size: proxy.size.width / 3))
                                        .fixedSize()
                                        .position(x: proxy.size.width * 0.85,
                                                  y: proxy.size.height * 0.07)
                                        .foregroundStyle(.appBlack.opacity(0.1))
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
                                    
                                    // Page icon + title and description
                                    VStack(spacing: 0) {
                                        HStack(alignment: .center) {
                                            // Icon
                                            Image(homeManager.currentPage.icon)
                                                .resizable()
                                                .frame(width: proxy.size.width / 10)
                                                .frame(height: proxy.size.width / 10)
                                            
                                            // Title
                                            Text(homeManager.currentPage.title)
                                                .font(.custom(Font.customBold, size: proxy.size.width / 16))
                                                .foregroundStyle(.appWhite)
                                            
                                            Spacer()
                                        }
                                        
                                        HStack {
                                            // Description
                                            Text(homeManager.currentPage.description)
                                                .font(.custom(Font.customRegular, size: proxy.size.width / 28))
                                                .foregroundStyle(.appWhite)
                                            
                                            Spacer()
                                        }
                                    }
                                    .padding(.top, proxy.size.height / 20)
                                    
                                    // Pagenation navigator
                                    HStack {
                                        Button(action: {
                                            homeManager.navigatePage(page: .history)
                                        }, label: {
                                            Text("面接履歴")
                                                .foregroundStyle(homeManager.currentPage == HomePage.history ?
                                                    .appPrimary : .appWhite)
                                        })
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            homeManager.navigatePage(page: .mockInterview)
                                        }, label: {
                                            Text("模擬面接")
                                                .foregroundStyle(homeManager.currentPage == HomePage.mockInterview ?
                                                    .appPrimary : .appWhite)
                                        })
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            homeManager.navigatePage(page: .analyze)
                                        }, label: {
                                            Text("面接分析")
                                                .foregroundStyle(homeManager.currentPage == HomePage.analyze ?
                                                    .appPrimary : .appWhite)
                                        })
                                    }
                                    .font(.custom(Font.customMedium, size: proxy.size.width / 28))
                                    .padding(proxy.size.width / 48)
                                    .padding(.horizontal, proxy.size.width / 14)
                                    .background {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: proxy.size.width / 32)
                                                .stroke(.appWhite, lineWidth: 1)
                                            HStack {
                                                if homeManager.currentPage == HomePage.analyze {
                                                    Spacer()
                                                }
                                                
                                                RoundedRectangle(cornerRadius: proxy.size.width / 32)
                                                    .frame(width: proxy.size.width / 3)
                                                    .foregroundStyle(.appWhite)
                                                
                                                if homeManager.currentPage == HomePage.history {
                                                    Spacer()
                                                }
                                            }
                                        }
                                    }
                                    .padding(.top, proxy.size.height / 48)
                                }
                                .padding()
                            }
                            .frame(maxHeight: proxy.size.height / 3)
                        }
                        
                        // Body
                        if homeManager.currentPage == .history {
                            EmptyView()
                        } else if homeManager.currentPage == .mockInterview {
                            MockInterviewPage(proxy: proxy, homeManager: homeManager)
                        } else if homeManager.currentPage == .analyze {
                            EmptyView()
                        }
                        
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
