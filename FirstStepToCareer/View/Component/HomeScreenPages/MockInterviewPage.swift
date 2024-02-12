//
//  MockInterviewPage.swift
//  FirstStepToCareer
//
//  Created by SeungWoo Hong on 2024/01/24.
//

import SwiftUI

struct MockInterviewPage: View {
    
    let proxy: GeometryProxy
    @ObservedObject var homeManager: HomeManager
    
    var body: some View {
        VStack(spacing: proxy.size.height / 60) {
            VStack(spacing: proxy.size.height / 80) {
                HStack {
                    Text("会社名")
                        .font(.custom(Font.customMedium, size: proxy.size.width / 24))
                        .foregroundStyle(.appBlack)
                    Spacer()
                }
                
                HStack(spacing: proxy.size.width / 48) {
                    Image(systemName: "building.2.fill")
                        .resizable()
                        .frame(width: proxy.size.width / 16)
                        .frame(height: proxy.size.width / 16)
                        .foregroundStyle(.appWhite)
                    
                    ZStack {
                        TextField("就活一歩株式会社", text: $homeManager.currentCompanyName)
                            .font(.custom(Font.customRegular, size: proxy.size.width / 26))
                            .padding(proxy.size.width / 48)
                            .background(.appWhite)
                            .clipShape(RoundedRectangle(cornerRadius: proxy.size.width / 32))
                            .disableAutocorrection(true)
                            .textInputAutocapitalization(.never)
                            .disabled(homeManager.isShowLoadingIndicator)
                        
                        if !homeManager.currentCompanyName.isEmpty {
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
                                .disabled(homeManager.isShowLoadingIndicator)
                            }
                        }
                    }
                }
                .padding(proxy.size.width / 48)
                .background(.appPrimary)
                .clipShape(RoundedRectangle(cornerRadius: proxy.size.width / 32))
                .shadow(color: .appBlack.opacity(0.25), radius: 2, y: 2)
                
                VStack(spacing: proxy.size.height / 80) {
                    HStack {
                        Text("活動区分")
                            .font(.custom(Font.customMedium, size: proxy.size.width / 24))
                            .foregroundStyle(.appBlack)
                        Spacer()
                    }

                    HStack {
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
                        .disabled(homeManager.isShowLoadingIndicator)
                        
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
                        .disabled(homeManager.isShowLoadingIndicator)
                    }
                    
                    VStack(spacing: proxy.size.height / 80) {
                        HStack {
                            Text("企業分野")
                                .font(.custom(Font.customMedium, size: proxy.size.width / 24))
                                .foregroundStyle(.appBlack)
                            Spacer()
                        }
                        
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
                        }.disabled(homeManager.isShowLoadingIndicator)
                    }
                    
                    VStack(spacing: proxy.size.height / 80) {
                        // Label
                        HStack {
                            Text("希望職種")
                                .font(.custom(Font.customMedium, size: proxy.size.width / 24))
                                .foregroundStyle(.appBlack)
                            Spacer()
                        }
                        
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
                        }.disabled(homeManager.isShowLoadingIndicator)
                    }
                    
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
                        .disabled(homeManager.isShowLoadingIndicator)
                    }
                    
                    if homeManager.isValidationFailed {
                        Text("未入力、または選択していない項目があります")
                            .font(.custom(Font.customMedium, size: proxy.size.width / 32))
                            .foregroundStyle(.appRed)
                            .frame(maxWidth: .infinity)
                    }
                    
                    if homeManager.isConnectionFailed {
                        Text("サーバーに接続できませんでした")
                            .font(.custom(Font.customMedium, size: proxy.size.width / 32))
                            .foregroundStyle(.appRed)
                            .frame(maxWidth: .infinity)
                    }
                    
                    if homeManager.isUnknownError {
                        Text("エラーが発生しました")
                            .font(.custom(Font.customMedium, size: proxy.size.width / 32))
                            .foregroundStyle(.appRed)
                            .frame(maxWidth: .infinity)
                    }
                    
                    Button(action: {
                        homeManager.prepareInterview()
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
                    .padding(homeManager.isValidationFailed || homeManager.isConnectionFailed ?
                        .bottom : .vertical)
                    .disabled(homeManager.isShowLoadingIndicator)
                }
            }
        }
        .padding()
    }
}

#Preview {
    GeometryReader(content: { geometry in
        MockInterviewPage(proxy: geometry, homeManager: HomeManager())
    })
}
