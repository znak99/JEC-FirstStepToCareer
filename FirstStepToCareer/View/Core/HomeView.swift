//
//  HomeView.swift
//  FirstStepToCareer
//
//  Created by SeungWoo Hong on 2024/01/24.
//

import SwiftUI

struct HomeView: View {
    
    @StateObject var homeManager = HomeManager()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appWhite.ignoresSafeArea()
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                homeManager.pageSwipeOffset = value.translation
                            }
                            .onEnded { value in
                                homeManager.pageSwipeOffset = .zero
                                homeManager.swipePage(swipeDistance: value.translation.width)
                            }
                    )
                
                GeometryReader { proxy in
                    VStack {
                        ZStack {
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
                            
                            Group {
                                Text(homeManager.bgText)
                                    .font(.custom(Font.customBlack, size: proxy.size.width / 3))
                                    .fixedSize()
                                    .position(x: proxy.size.width * 0.85,
                                              y: proxy.size.height * 0.07)
                                    .foregroundStyle(.appBlack.opacity(0.1))
                            }
                            
                            VStack {
                                HStack {
                                    Image("AppLogo-White")
                                        .resizable()
                                        .frame(width: proxy.size.width / 12)
                                        .frame(height: proxy.size.width / 12)
                                    
                                    Text("就活一歩")
                                        .font(.custom(Font.customSemiBold,
                                                      size: proxy.size.width / 20))
                                        .foregroundStyle(.appWhite)
                                    
                                    Spacer()
                                    
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
                                
                                VStack(spacing: 0) {
                                    HStack(alignment: .center) {
                                        Image(homeManager.currentPage.icon)
                                            .resizable()
                                            .frame(width: proxy.size.width / 10)
                                            .frame(height: proxy.size.width / 10)
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
                                    .disabled(homeManager.isShowLoadingIndicator)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        homeManager.navigatePage(page: .mockInterview)
                                    }, label: {
                                        Text("模擬面接")
                                            .foregroundStyle(homeManager.currentPage == HomePage.mockInterview ?
                                                .appPrimary : .appWhite)
                                    })
                                    .disabled(homeManager.isShowLoadingIndicator)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        homeManager.navigatePage(page: .analyze)
                                    }, label: {
                                        Text("面接分析")
                                            .foregroundStyle(homeManager.currentPage == HomePage.analyze ?
                                                .appPrimary : .appWhite)
                                    })
                                    .disabled(homeManager.isShowLoadingIndicator)
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
                        
                        ScrollView(.vertical, showsIndicators: false) {
                            if homeManager.currentPage == .history {
                                HistoryPage(proxy: proxy, homeManager: homeManager)
                            } else if homeManager.currentPage == .mockInterview {
                                MockInterviewPage(proxy: proxy, homeManager: homeManager)
                            } else if homeManager.currentPage == .analyze {
                                AnalyzePage(proxy: proxy, homeManager: homeManager)
                            }
                        }
                        .padding(.top)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    homeManager.pageSwipeOffset = value.translation
                                }
                                .onEnded { value in
                                    homeManager.pageSwipeOffset = .zero
                                    homeManager.swipePage(swipeDistance: value.translation.width)
                                }
                        )
                    }
                    
                    if homeManager.isShowLoadingIndicator {
                        LoadingIndicator(proxy: proxy)
                    }
                }
                if !homeManager.isAppReady {
                    SplashView()
                }
            }
            .onAppear {
                if !homeManager.isAppReady {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        DispatchQueue.main.async {
                            homeManager.isAppReady = true
                            homeManager.interviewInfoFieldInit()
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $homeManager.isNavigateToMockInterviewView) {
                MockInterviewView()
            }
        }
    }
}

#Preview {
    HomeView()
}
