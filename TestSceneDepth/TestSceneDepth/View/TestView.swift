//
//  TestView.swift
//  TestSceneDepth
//
//  Created by Shirai on 2024/01/14.
//

import SwiftUI

import AudioToolbox

// 小規模の機能のテストを行うビュー
// このコードはバイブレーションを確かめるため

struct TestView: View {
    @State var sliderValue: Double = 1.0

    var body: some View {
        Button(action: {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }) {
            Text("成功時のバイブ")
        }
        Button(action: {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }) {
            Text("失敗時のバイブ")
        }
        Button(action: {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }) {
            Text("警告時のバイブ")
        }
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }) {
            Text("軽いバイブ")
        }
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }) {
            Text("普通のバイブ")
        }
        Button(action: {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }) {
            Text("強いバイブ")
        }
        Button(action: {
            UISelectionFeedbackGenerator().selectionChanged()
        }) {
            Text("フィードバック時のバイブ")
        }
        
        
        
        Button(action: {
            AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(kSystemSoundID_Vibrate)) {}
        }) {
            Text("強い長めのバイブ")
        }
        Button(action: {
            AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(1102)) {}
        }) {
            Text("1102")
        }
        Button(action: {
            AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(1519)) {}
        }) {
            Text("1519")
        }
        Button(action: {
            AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(1520)) {}
        }) {
            Text("1520")
        }
        Button(action: {
            AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(1521)) {}
        }) {
            Text("1521")
        }
        HStack {
                    Text("\(format(sliderValue))")
                    Slider(value: $sliderValue)
                }
                .frame(width: 300)
        Button(action: {
            print(sliderValue)
            for _ in 0...Int(sliderValue*100) {
            AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(kSystemSoundID_Vibrate)) {}
            sleep(1)
        }
        }) {
            Text("複数回")
        }
    }
    func format(_ num: Double) -> String {
        let result = String(Int(round(num*100)))
        return result
    }
}

#Preview {
    TestView()
}
