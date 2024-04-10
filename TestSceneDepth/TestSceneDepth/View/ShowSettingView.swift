//
//  ShowImageView.swift
//  TestSceneDepth
//
//  Created by Shirai on 2023/08/04.
//

import SwiftUI

// 表示するビューや画像の種類を設定

struct ShowSettingView: View {
    @Binding var showMode: Int
    @Binding var selectImage1: Int
    @Binding var selectImage2: Int
    
    var body: some View {
        
        Picker(selection: $showMode, label: Text("画像")){
            Text("段差").tag(1)
            Text("物体").tag(2)
            Text("テスト").tag(3)
            Text("計測").tag(4)
        }.pickerStyle(SegmentedPickerStyle())
        
        HStack{
//            Text("メイン")
            Picker(selection: $selectImage1, label: Text("画像")){
                Text("RGB").tag(0)
                Text("深度").tag(1)
                Text("段差").tag(2)
                Text("線分").tag(3)
                Text("色エ").tag(4)
                Text("信頼").tag(5)
                Text("被1").tag(6)
                Text("被2").tag(7)
            }.pickerStyle(SegmentedPickerStyle())
        }

    }
}

