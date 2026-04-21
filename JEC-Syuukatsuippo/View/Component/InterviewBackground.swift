//
//  InterviewBackground.swift
//  JEC-Syuukatsuippo
//
//  Created by SeungWoo Hong on 2024/02/13.
//

import SwiftUI

struct InterviewBackground: View {
    
    let proxy: GeometryProxy
    
    @ObservedObject var interviewManager: InterviewManager
    
    var body: some View {
        VStack {
            HStack(alignment: .bottom) {
                ZStack {
                    Circle()
                        .fill(.clear)
                        .frame(width: proxy.size.width / 22)
                    Circle()
                        .stroke(.clear, lineWidth: 3)
                        .frame(width: proxy.size.width / 16)
                }
                Text(interviewManager.headerText)
                    .font(.custom(Font.customRegular, size: proxy.size.width / 24))
                    .foregroundStyle(.clear)
                Spacer()
                Image(systemName: "xmark")
                    .resizable()
                    .frame(width: proxy.size.width / 20)
                    .frame(height: proxy.size.width / 20)
                    .foregroundStyle(.clear)
                    .padding(proxy.size.width / 48)
                    .background {
                        RoundedRectangle(cornerRadius: proxy.size.width / 32)
                            .stroke(.clear, lineWidth: 1)
                    }
            }
            
            if interviewManager.isReferencePointGenerated {
                Text(InterviewInfoTemp.shared.companyName)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .font(.custom(Font.customBold, size: proxy.size.width / 16))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                    .background {
                        Capsule()
                            .foregroundStyle(.white)
                    }
                
                Image("AppLogo-White")
                    .resizable()
                    .frame(width: proxy.size.width / 1.3, height: proxy.size.width / 1.3)
                    .padding(.top)
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    GeometryReader(content: { proxy in
        InterviewBackground(proxy: proxy, interviewManager: InterviewManager())
    })
}
