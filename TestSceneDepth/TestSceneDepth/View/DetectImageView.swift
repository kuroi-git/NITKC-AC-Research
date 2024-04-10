//
//  DetectImageView.swift
//  TestSceneDepth
//
//  Created by Shirai on 2023/11/20.
//

import SwiftUI
import Vision

// 物体検出の結果を表示するためのビュー

struct DetectImageView: View {
    var myImage: UIImage                        // RGB画像
    @ObservedObject var cml = CoreMLFuncs()     // CoreMLの関数
    @Binding var yoloModel: VNCoreMLModel?      // 物体検出モデル
    
    var body: some View {
        // 関数predictは複数の変数が帰ってくる（img, str）
        let myColorImage = CoreMLFuncs.predict(image: myImage, yolo: yoloModel!)
        Button(action:{UIImageWriteToSavedPhotosAlbum(myColorImage.img, self, nil, nil)}){Text("保存")}
        Image(uiImage: myColorImage.img)
            .resizable()
//            .rotationEffect(.degrees(90))
            .aspectRatio(contentMode: .fit) // アスペクト比を維持し、指定した幅に収まるようにします
            .frame(width: 300)
        // 物体検出の結果を表示
        Text(myColorImage.str)
            .font(.system(size: 10))
            .lineLimit(10)


    }
}
