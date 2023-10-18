//
//  MockInterviewPage.swift
//  JEC-FirstStepToCareer
//
//  Created by SeungWoo Hong on 2023/10/19.
//

import SwiftUI

struct MockInterviewPage: View {
    
    let proxy: GeometryProxy
    @ObservedObject var homeManager: HomeManager
    
    var body: some View {
        VStack {
            if homeManager.isFieldFocused {
                Spacer()
            }
            
            // Company name field
            VStack(spacing: proxy.size.height / 80) {
                // Label
                HStack {
                    Text("会社名")
                        .font(.custom(Font.customMedium, size: proxy.size.width / 24))
                        .foregroundStyle(.appBlack)
                    if !homeManager.isFieldFocused {
                        Spacer()
                    }
                }
                
                // Field
                HStack(spacing: proxy.size.width / 48) {
                    Image(systemName: "building.2.fill")
                        .resizable()
                        .frame(width: proxy.size.width / 16)
                        .frame(height: proxy.size.width / 16)
                        .foregroundStyle(.appWhite)
                    
                    ZStack {
                        TextField("就活一歩株式会社", text: $homeManager.companyName)
                            .font(.custom(Font.customRegular, size: proxy.size.width / 26))
                            .padding(proxy.size.width / 48)
                            .background(.appWhite)
                            .clipShape(RoundedRectangle(cornerRadius: proxy.size.width / 32))
                            .disableAutocorrection(true)
                            .textInputAutocapitalization(.never)
                        
                        if !homeManager.companyName.isEmpty {
                            HStack {
                                Spacer()
                                Button(action: homeManager.clearField, label: {
                                    Image(systemName: "x.circle.fill")
                                        .resizable()
                                        .frame(width: proxy.size.width / 20)
                                        .frame(height: proxy.size.width / 20)
                                        .foregroundStyle(.appGray)
                                        .padding(.trailing, proxy.size.width / 48)
                                })
                            }
                        }
                    }
                    
                }
                .padding(proxy.size.width / 48)
                .background(.appPrimary)
                .clipShape(RoundedRectangle(cornerRadius: proxy.size.width / 32))
                .shadow(color: .appBlack.opacity(0.25), radius: 2, y: 2)
            }
            
            if homeManager.isFieldFocused {
                Spacer()
            }
        }
        .padding([.top, .horizontal])
        .onAppear {
            // Keyboard up
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardDidShowNotification,
                                                   object: nil,
                                                   queue: .main) { _ in
                withAnimation(.linear(duration: 0.2)) {
                    homeManager.isFieldFocused = true
                }
            }

            // Keyboard down
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardDidHideNotification,
                                                   object: nil,
                                                   queue: .main) { _ in
                withAnimation(.linear(duration: 0.2)) {
                    homeManager.isFieldFocused = false
                }
            }
        }
    }
}

#Preview {
    GeometryReader(content: { proxy in
        MockInterviewPage(proxy: proxy, homeManager: HomeManager())
    })
}
