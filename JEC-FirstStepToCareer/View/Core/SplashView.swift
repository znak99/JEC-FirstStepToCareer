//
//  SplashView.swift
//  JEC-FirstStepToCareer
//
//  Created by SeungWoo Hong on 2023/10/19.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            // Background
            LinearGradient(colors: [.appBGGradient1, .appBGGradient2],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
            .ignoresSafeArea()
            
            GeometryReader(content: { proxy in
                HStack {
                    Spacer()
                    
                    // Logo and title
                    VStack {
                        Spacer()
                        
                        // Logo
                        Image("AppLogo-White")
                            .resizable()
                            .frame(width: proxy.size.width / 2)
                            .frame(height: proxy.size.width / 2)
                        
                        // Title
                        Text("就活一歩")
                            .font(.custom(Font.customBlack, size: proxy.size.width / 10))
                            .foregroundStyle(.appWhite)
                        
                        Spacer()
                    }
                    
                    Spacer()
                }
            })
        }
    }
}

#Preview {
    SplashView()
}
