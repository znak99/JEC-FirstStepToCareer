//
//  LoadingIndicator.swift
//  JEC-FirstStepToCareer
//
//  Created by SeungWoo Hong on 2023/10/29.
//

import SwiftUI

struct LoadingIndicator: View {
    
    let proxy: GeometryProxy
    
    @State var leftItemYAxisRate: CGFloat = -4
    @State var centerItemYAxisRate: CGFloat = -4
    @State var rightItemYAxisRate: CGFloat = -4
    
    var body: some View {
        ZStack {
            Color.appBlack.opacity(0.1)
                .ignoresSafeArea()
            Color.appWhite
            .clipShape(RoundedRectangle(cornerRadius: proxy.size.width / 24))
            .frame(width: proxy.size.width / 5)
            .frame(height: proxy.size.width / 7)
            .overlay {
                RoundedRectangle(cornerRadius: proxy.size.width / 24)
                    .stroke(.white, lineWidth: 1.5)
            }
            .shadow(radius: 4, y: 2)
            
            HStack {
                RoundedRectangle(cornerRadius: proxy.size.width / 36)
                    .frame(width: proxy.size.width / 36)
                    .frame(height: proxy.size.width / 24)
                    .offset(y: leftItemYAxisRate)
                RoundedRectangle(cornerRadius: proxy.size.width / 36)
                    .frame(width: proxy.size.width / 36)
                    .frame(height: proxy.size.width / 24)
                    .offset(y: centerItemYAxisRate)
                RoundedRectangle(cornerRadius: proxy.size.width / 36)
                    .frame(width: proxy.size.width / 36)
                    .frame(height: proxy.size.width / 24)
                    .offset(y: rightItemYAxisRate)
            }
            .foregroundStyle(.appPrimary)
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeIn(duration: 0.5).repeatForever()) {
                leftItemYAxisRate += 8
            }
            
            withAnimation(.easeIn(duration: 0.5).repeatForever().delay(0.25)) {
                centerItemYAxisRate += 8
            }
            
            withAnimation(.easeIn(duration: 0.5).repeatForever().delay(0.5)) {
                rightItemYAxisRate += 8
            }
        }
    }
}

#Preview {
    GeometryReader(content: { proxy in
        LoadingIndicator(proxy: proxy)
    })
}
