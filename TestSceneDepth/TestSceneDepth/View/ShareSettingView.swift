//
//  ShareSettingBiew.swift
//  TestSceneDepth
//
//  Created by Shirai on 2023/08/04.
//

// 各種設定値のためのビュー

import SwiftUI

struct ShareSettingView: View {
    // 引数として渡されたデータ
    @Binding var maxDistance: Float
    @Binding var opacity: Double
    @Binding var showError: Bool
    @Binding var canCapture: Bool
    @Binding var isSmoothed: Bool
    @Binding var showDistance: Bool
    
    @Binding var selectView1: Int
    @Binding var selectView2: Int
    
    @Binding var th1: Int
    @Binding var th2: Int
    
    @Binding var line_th: Int
    @Binding var length: Int
    @Binding var gap: Int
    
    var body: some View {
        HStack{
            HStack(){
                Text("段差:\n\(String(format:"%.2f",maxDistance))")
                Slider(value: $maxDistance, in: 0...3, step: 0.05)
            }
            
            HStack(){
                Text("有効距離:\n\(String(format:"%.2f",opacity))")
                Slider(value: $opacity, in: 0...10, step: 0.5)
            }
            
        }
        HStack(){
            Toggle(isOn: $showError) {Text(showError ? "赤" : "白")}
            Toggle(isOn: $canCapture) {Text(canCapture ? "撮影" : "非撮影")}
            Toggle(isOn: $isSmoothed) {Text(isSmoothed ? "平坦化" : "高速化")}
            Toggle(isOn: $showDistance) {Text(showDistance ? "表示" : "非表示")}
        }
        
        //Spacer().frame(height: 20)
        /*
         Text("エッジ")
         .border(Color.red, width:3)
         */
        HStack(spacing: 20){
            Spacer()
            VStack{
                Text("閾値1(小): \(th1)")
                Stepper(value: $th1, step: 10) {}
            }
            VStack{
                Text("閾値2(大): \(th2)")
                Stepper(value: $th2, step: 10) {}
            }
            Spacer().frame(width: 40)
        }
        //Spacer().frame(height: 20)
        /*Text("直線検出")
         .border(Color.red, width:2)
         */
        HStack(spacing: 20){
            Spacer()
            VStack{
                Text("閾値: \(line_th)")
                Stepper(value: $line_th, step: 10){}
            }
            VStack{
                Text("長さ: \(length)")
                Stepper(value: $length, step: 10) {}
            }
            VStack{
                Text("差: \(gap)")
                Stepper(value: $gap, step: 10) {}
            }
            Spacer()
        }
    }
}

