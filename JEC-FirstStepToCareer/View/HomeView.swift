//
//  HomeView.swift
//  JEC-FirstStepToCareer
//
//  Created by SeungWoo Hong on 2023/10/19.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        Text("ホームビュー")
            .font(.custom(Font.customBold, size: 24))
        Image("AppLogo-White")
            .resizable()
            .frame(width: 100, height: 100)
            .background(.black)
    }
}

#Preview {
    HomeView()
}
