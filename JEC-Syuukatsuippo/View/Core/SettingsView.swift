//
//  SettingsView.swift
//  JEC-Syuukatsuippo
//
//  Created by SeungWoo Hong on 2024/02/13.
//

import SwiftUI

struct SettingsView: View {
    
    @StateObject private var settingsManager: SettingsManager = .init()
    @ObservedObject var homeManaer: HomeManager
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.appWhite.ignoresSafeArea()
                
                VStack {
                    HStack {
                        Text("設定")
                            .font(.custom(Font.customSemiBold, size: proxy.size.width / 16))
                            .foregroundStyle(.appBlack)
                        Spacer()
                        Button(action: {
                            dismiss()
                        }, label: {
                            Image(systemName: "xmark")
                                .resizable()
                                .frame(width: proxy.size.width / 20)
                                .frame(height: proxy.size.width / 20)
                                .foregroundStyle(.appBlack)
                                .padding(proxy.size.width / 48)
                                .background {
                                    RoundedRectangle(cornerRadius: proxy.size.width / 32)
                                        .stroke(.appBlack, lineWidth: 1)
                                }
                        })
                    }
                    
                    Divider()
                    VStack {
                        HStack {
                            Text("データ管理")
                                .font(.custom(Font.customBold, size: proxy.size.width / 20))
                                .foregroundStyle(.appGray)
                            Spacer()
                        }
                        
                        Button(action: {
                            settingsManager.isDeleteAllAppDataConfirm.toggle()
                        }, label: {
                            Text("すべてのデータを削除")
                                .foregroundStyle(.appRed)
                                .font(.custom(Font.customSemiBold, size: proxy.size.width / 24))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, proxy.size.width / 48)
                                .background(.white)
                                .clipShape(RoundedRectangle(cornerRadius: proxy.size.width / 24))
                        })
                        .shadow(color: .black.opacity(0.1), radius: 2, y: 2)
                        .alert("警告", isPresented: $settingsManager.isDeleteAllAppDataConfirm) {
                            Button("はい", role: .destructive) {
                                homeManaer.deleteAllAppData()
                            }
                            Button("いいえ", role: .cancel) {}
                        } message: {
                            Text("アプリ内のすべてのデータを削除します。")
                        }

                        
                        Button(action: {
                            homeManaer.addDummyMockInterviewData()
                        }, label: {
                            Text("サンプルデータ追加")
                                .foregroundStyle(.appPrimary)
                                .font(.custom(Font.customSemiBold, size: proxy.size.width / 24))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, proxy.size.width / 48)
                                .background(.white)
                                .clipShape(RoundedRectangle(cornerRadius: proxy.size.width / 24))
                        })
                        .shadow(color: .black.opacity(0.1), radius: 2, y: 2)
                        .padding(.top)
                    }
                    Spacer()
                }
                .padding()
            }
            .toolbar(.hidden)
        }
    }
}

#Preview {
    SettingsView(homeManaer: HomeManager())
}
