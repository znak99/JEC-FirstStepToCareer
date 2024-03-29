//
//  MockInterviewHeader.swift
//  JEC-FirstStepToCareer
//
//  Created by SeungWoo Hong on 2023/10/30.
//

import SwiftUI

struct MockInterviewHeader: View {
    
    let proxy: GeometryProxy
    @ObservedObject var interviewManager: MockInterviewManager
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        HStack(alignment: .bottom) {
            ZStack {
                Circle()
                    .fill(.appRed)
                    .frame(width: proxy.size.width / 22)
                    .opacity(interviewManager.recIconOpacity)
                Circle()
                    .stroke(.appRed, lineWidth: 3)
                    .frame(width: proxy.size.width / 16)
                    .opacity(interviewManager.recIconOpacity)
            }
            Text(interviewManager.headerText)
                .font(.custom(Font.customRegular, size: proxy.size.width / 24))
                .foregroundStyle(.appWhite)
            Spacer()
            Button(action: { dismiss() }, label: {
                Image(systemName: "xmark")
                    .resizable()
                    .frame(width: proxy.size.width / 20)
                    .frame(height: proxy.size.width / 20)
                    .foregroundStyle(.appWhite)
            })
            .padding(proxy.size.width / 48)
            .background {
                RoundedRectangle(cornerRadius: proxy.size.width / 32)
                    .stroke(.appWhite, lineWidth: 1)
            }
        }
    }
}

#Preview {
    GeometryReader(content: { proxy in
        MockInterviewHeader(proxy: proxy,
                            interviewManager: MockInterviewManager())
    })
}
