//
//  CompanyTypeSelectorView.swift
//  JEC-FirstStepToCareer
//
//  Created by SeungWoo Hong on 2023/10/19.
//

import SwiftUI

struct CompanyTypeSelectorView: View {
    
    let proxy: GeometryProxy
    @ObservedObject var homeManager: HomeManager
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            // Page title
            HStack {
                // Title
                Text("企業分野を\n選択してください")
                    .font(.custom(Font.customBlack, size: proxy.size.width / 16))
                
                Spacer()
                
                // Dismiss
                Button(action: {
                    dismiss()
                }, label: {
                    Image(systemName: "xmark")
                        .resizable()
                        .frame(width: proxy.size.width / 28)
                        .frame(height: proxy.size.width / 28)
                        .foregroundStyle(.appBlack)
                })
                .padding(proxy.size.width / 48)
                .background {
                    RoundedRectangle(cornerRadius: proxy.size.width / 32)
                        .stroke(.appBlack, lineWidth: 1)
                }
            }
            .padding(.top)
            
            List(CompanyType.allCases) { type in
                if type != .none {
                    Button(action: {
                        homeManager.selectCompanyType(type: type)
                        dismiss()
                    }, label: {
                        HStack {
                            Rectangle()
                                .fill(.appPrimary)
                                .frame(width: 8)
                                .frame(height: proxy.size.width / 12)
                            Text(type.rawValue)
                                .font(.custom(Font.customMedium, size: proxy.size.width / 24))
                            Spacer()
                        }
                        .padding(proxy.size.width / 48)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: proxy.size.width / 48))
                        .shadow(color: .appBlack.opacity(0.25), radius: 2, y: 2)
                    })
                }
            }
            .listStyle(.plain)
            
            Spacer()
        }
        .padding()
        .toolbar(.hidden)
    }
}

#Preview {
    GeometryReader(content: { proxy in
        CompanyTypeSelectorView(proxy: proxy, homeManager: HomeManager())
    })
}
