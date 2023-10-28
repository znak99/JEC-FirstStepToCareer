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
        VStack(spacing: proxy.size.height / 60) {
            // Company name field
            VStack(spacing: proxy.size.height / 80) {
                // Label
                HStack {
                    Text("会社名")
                        .font(.custom(Font.customMedium, size: proxy.size.width / 24))
                        .foregroundStyle(.appBlack)
                    Spacer()
                }
                
                // Field
                HStack(spacing: proxy.size.width / 48) {
                    // Icon
                    Image(systemName: "building.2.fill")
                        .resizable()
                        .frame(width: proxy.size.width / 16)
                        .frame(height: proxy.size.width / 16)
                        .foregroundStyle(.appWhite)
                    
                    // Textfield
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
            .offset(y: homeManager.isFieldFocused ? proxy.size.height / 4 : 0)
            
            if !homeManager.isFieldFocused {
                // Interview type
                VStack(spacing: proxy.size.height / 80) {
                    // Label
                    HStack {
                        Text("活動区分")
                            .font(.custom(Font.customMedium, size: proxy.size.width / 24))
                            .foregroundStyle(.appBlack)
                        Spacer()
                    }
                    // Interview type buttons
                    HStack {
                        // Newcomer
                        Button(action: {
                            homeManager.selectInterviewType(type: .newcomer)
                        }, label: {
                            HStack(spacing: proxy.size.width / 48) {
                                Image(systemName: InterviewType.newcomer.icon)
                                    .resizable()
                                    .frame(width: proxy.size.width / 20)
                                    .frame(height: proxy.size.width / 20)
                                Text(InterviewType.newcomer.rawValue)
                                    .font(.custom(Font.customMedium, size: proxy.size.width / 24))
                            }
                            .frame(width: proxy.size.width / 2.3)
                        })
                        .foregroundStyle(homeManager.currentInterviewType == .newcomer ?
                            .appWhite : .appBlack)
                        .padding(.vertical, proxy.size.height / 120)
                        .background(homeManager.currentInterviewType == .newcomer ? .appPrimary : .white)
                        .clipShape(RoundedRectangle(cornerRadius: proxy.size.width / 32))
                        .shadow(color: .appBlack.opacity(0.25), radius: 2, y: 2)
                        
                        Spacer()
                        
                        // Experienced
                        Button(action: {
                            homeManager.selectInterviewType(type: .experienced)
                        }, label: {
                            HStack(spacing: proxy.size.width / 48) {
                                Image(systemName: InterviewType.experienced.icon)
                                    .resizable()
                                    .frame(width: proxy.size.width / 20)
                                    .frame(height: proxy.size.width / 20)
                                Text(InterviewType.experienced.rawValue)
                                    .font(.custom(Font.customMedium, size: proxy.size.width / 24))
                            }
                            .frame(width: proxy.size.width / 2.3)
                        })
                        .foregroundStyle(homeManager.currentInterviewType == .experienced ?
                            .appWhite : .appBlack)
                        .padding(.vertical, proxy.size.height / 120)
                        .background(homeManager.currentInterviewType == .experienced ? .appPrimary : .white)
                        .clipShape(RoundedRectangle(cornerRadius: proxy.size.width / 32))
                        .shadow(color: .appBlack.opacity(0.25), radius: 2, y: 2)
                    }
                }
                
                // Company type
                VStack(spacing: proxy.size.height / 80) {
                    // Label
                    HStack {
                        Text("企業分野")
                            .font(.custom(Font.customMedium, size: proxy.size.width / 24))
                            .foregroundStyle(.appBlack)
                        Spacer()
                    }
                    
                    // Navigate to select view
                    NavigationLink(destination: CompanyTypeSelectorView(proxy: proxy,
                                                                        homeManager: homeManager)) {
                        HStack {
                            Text(homeManager.currentCompanyType.rawValue)
                                .font(.custom(Font.customMedium, size: proxy.size.width / 28))
                                .foregroundStyle(homeManager.currentCompanyType == .none ? .appGray : .appBlack)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .resizable()
                                .frame(width: proxy.size.width / 48)
                                .frame(height: proxy.size.width / 32)
                                .foregroundStyle(.appPrimary)
                        }
                        .padding(proxy.size.width / 48)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: proxy.size.width / 32))
                        .shadow(color: .appBlack.opacity(0.25), radius: 2, y: 2)
                    }
                }
                
                // Career objective
                VStack(spacing: proxy.size.height / 80) {
                    // Label
                    HStack {
                        Text("希望職種")
                            .font(.custom(Font.customMedium, size: proxy.size.width / 24))
                            .foregroundStyle(.appBlack)
                        Spacer()
                    }
                    
                    // Navigate to select view
                    NavigationLink(destination: CareerTypeSelectorView(proxy: proxy,
                                                                       homeManager: homeManager)) {
                        HStack {
                            Text(homeManager.currentCareerType.rawValue)
                                .font(.custom(Font.customMedium, size: proxy.size.width / 28))
                                .foregroundStyle(homeManager.currentCareerType == .none ? .appGray : .appBlack)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .resizable()
                                .frame(width: proxy.size.width / 48)
                                .frame(height: proxy.size.width / 32)
                                .foregroundStyle(.appPrimary)
                        }
                        .padding(proxy.size.width / 48)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: proxy.size.width / 32))
                        .shadow(color: .appBlack.opacity(0.25), radius: 2, y: 2)
                    }
                }
                
                // Save interview info
                HStack {
                    Spacer()
                    Button(action: {
                        homeManager.isSaveInterviewInfo.toggle()
                    }, label: {
                        HStack(alignment: .center, spacing: proxy.size.width / 120) {
                            Image(homeManager.isSaveInterviewInfo ? "CheckBox-On" : "CheckBox-Off")
                                .resizable()
                                .frame(width: proxy.size.width / 20)
                                .frame(height: proxy.size.width / 20)
                            Text("この情報を保存する")
                                .font(.custom(Font.customMedium, size: proxy.size.width / 32))
                                .foregroundStyle(.appGray)
                                .underline()
                        }
                    })
                }
                
                if homeManager.isValidationFailed {
                    Text("未入力、または選択していない項目があります")
                        .font(.custom(Font.customMedium, size: proxy.size.width / 32))
                        .foregroundStyle(.appRed)
                        .frame(maxWidth: .infinity)
                }
                
                // Start mock interview
                Button(action: {
                    homeManager.initializeMockInterview()
                }, label: {
                    Text("模擬面接を始める")
                        .font(.custom(Font.customBold, size: proxy.size.width / 20))
                        .foregroundStyle(.appWhite)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, proxy.size.height / 100)
                })
                .background(.appPrimary)
                .clipShape(RoundedRectangle(cornerRadius: proxy.size.width / 32))
                .shadow(color: .appBlack.opacity(0.25), radius: 2, y: 2)
                .padding(homeManager.isValidationFailed ? .bottom : .vertical)
            }
        }
        .padding()
        .onAppear {
            // Fill interview info field at first time to launch app
            if !homeManager.isAppReady {
                homeManager.updateMockInterviewFields()
            }
            
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
