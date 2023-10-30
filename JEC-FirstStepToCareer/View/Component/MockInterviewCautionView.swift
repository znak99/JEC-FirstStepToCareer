//
//  MockInterviewCautionView.swift
//  JEC-FirstStepToCareer
//
//  Created by SeungWoo Hong on 2023/10/30.
//

import SwiftUI

struct MockInterviewCautionView: View {
    
    let proxy: GeometryProxy
    @ObservedObject var interviewManager: MockInterviewManager
    
    @State var headerAnimationBlur: Double = 1.0
    @State var headerAnimationOpacity: Double = 0
    @State var headerAnimationOffsetY: Double = -16
    
    @State var bodyAnimationBlur: Double = 1.0
    @State var bodyAnimationOpacity: Double = 0
    @State var bodyAnimationOffsetY: Double = -16
    
    @State var buttonAnimationBlur: Double = 1.0
    @State var buttonAnimationOpacity: Double = 0
    @State var buttonAnimationOffsetY: Double = -16
    
    var body: some View {
        // Cautions
        VStack {
            HStack {
                Circle()
                    .frame(width: proxy.size.width / 20)
                    .frame(height: proxy.size.width / 20)
                    .foregroundStyle(.appPrimary)
                
                Text("確認事項")
                    .font(.custom(Font.customMedium, size: proxy.size.width / 20))
                    .foregroundStyle(.appWhite)
                
                Spacer()
            }
            .blur(radius: headerAnimationBlur)
            .opacity(headerAnimationOpacity)
            .offset(y: headerAnimationOffsetY)
            
            ScrollView(.vertical, showsIndicators: false) {
                Text("・模擬面接の際、正しい評価を行うために携帯は固定してください。")
                    .padding(.bottom)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.leading)
                Text("・顔がよく見えるよう、適当な明るさを保った環境で行ってください。")
                    .padding(.bottom)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.leading)
                Text("・音声認識を行っているため、静かな環境で行ってください。")
                    .padding(.bottom)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.leading)
                Text("・AI言語モデルを使っているため、正しい質問が出ない場合があります。模擬面接画面の下の質問再生成ボタンを利用してください。")
                    .padding(.bottom)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.leading)
                Text("・「確認しました」ボタンを押すと顔認識を始めます。模擬面接中の動きの評価は最初に認識した顔の位置から行われます。")
                    .padding(.bottom)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.leading)
            }
            .font(.custom(Font.customRegular, size: proxy.size.width / 28))
            .foregroundStyle(.appBlack)
            .padding(proxy.size.width / 32)
            .frame(maxWidth: .infinity)
            .frame(maxHeight: .infinity)
            .background(.appWhite)
            .clipShape(RoundedRectangle(cornerRadius: proxy.size.width / 32))
            .overlay {
                RoundedRectangle(cornerRadius: proxy.size.width / 48)
                    .stroke(.appPrimary, lineWidth: 4)
            }
            .blur(radius: bodyAnimationBlur)
            .opacity(bodyAnimationOpacity)
            .offset(y: bodyAnimationOffsetY)
            
            Button(action: {
                interviewManager.isStartInterview = true
            }, label: {
                Text("確認しました")
                    .font(.custom(Font.customBold, size: proxy.size.width / 20))
                    .foregroundStyle(.appWhite)
            })
            .frame(maxWidth: .infinity)
            .padding(.vertical, proxy.size.height / 96)
            .background(.appPrimary)
            .clipShape(RoundedRectangle(cornerRadius: proxy.size.width / 48))
            .padding(.top)
            .blur(radius: buttonAnimationBlur)
            .opacity(buttonAnimationOpacity)
            .offset(y: buttonAnimationOffsetY)
        }
        .frame(maxWidth: proxy.size.width / 1.2)
        .frame(maxHeight: proxy.size.height / 1.5)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).delay(0.5)) {
                headerAnimationBlur -= 1.0
                headerAnimationOpacity += 1
                headerAnimationOffsetY += 16
            }
            
            withAnimation(.easeInOut(duration: 1.5).delay(1.0)) {
                bodyAnimationBlur -= 1.0
                bodyAnimationOpacity += 1
                bodyAnimationOffsetY += 16
            }
            
            withAnimation(.easeInOut(duration: 1.5).delay(1.5)) {
                buttonAnimationBlur -= 1.0
                buttonAnimationOpacity += 1
                buttonAnimationOffsetY += 16
            }
        }
    }
}

#Preview {
    GeometryReader(content: { proxy in
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            MockInterviewCautionView(proxy: proxy, interviewManager: MockInterviewManager())
        }
    })
}
