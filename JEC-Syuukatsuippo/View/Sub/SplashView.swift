//
//  SplashView.swift
//  JEC-Syuukatsuippo
//
//  Created by SeungWoo Hong on 2024/02/13.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [.appBGGradient1, .appBGGradient2],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
            .ignoresSafeArea()
            
            GeometryReader(content: { proxy in
                HStack {
                    Spacer()
                    
                    VStack {
                        Spacer()
                        
                        Image("AppLogo-White")
                            .resizable()
                            .frame(width: proxy.size.width / 2)
                            .frame(height: proxy.size.width / 2)
                        
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
