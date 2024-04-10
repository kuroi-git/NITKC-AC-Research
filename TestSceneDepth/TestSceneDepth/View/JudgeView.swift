//
//  TestView.swift
//  TestSceneDepth
//
//  Created by Shirai on 2023/11/20.
//

import SwiftUI
import Vision
import opencv2

// 危険判断の結果を表示するためのビュー

struct JudgeView: View {
    var colorImage: UIImage     // RGB画像
//    var lineImage: UIImage
    @ObservedObject var cml = CoreMLFuncs()     // CoreMLの関数集クラス
    @Binding var yoloModel: VNCoreMLModel?      // モデル
    
    @State var canCapture: Bool = false         // 保存するかどうか
    
    var depthData: [[Float32]] = []
    var lines: [[Point]] = []
    
    var body: some View {
        let objects = CoreMLFuncs.getObjects(image: colorImage, yolo: yoloModel!)               // 検出物の名前とバウンディングボックスと信頼度を取得
        var daa = DataAnalyzeAlgorithm(depthData:depthData, lines:lines, objects:objects)       // 危険判断のためのデータ転送
        var result = daa.getInfo(myImage:colorImage, canCapture:canCapture)                     // 危険判断を行う、色々な情報が帰ってくる
        Toggle(isOn: $canCapture) {Text(canCapture ? "撮影" : "非撮影")}
        Text("中心座標距離: "+String(format: "%.3f,%d,%d",  depthData[Int(depthData.count/2)][Int(depthData[0].count/2)], Int(depthData.count),Int(depthData[0].count)))
        
        Image(uiImage: colorImage.rotateImageLeft90Degrees(colorImage)!)
            .resizable()
            .aspectRatio(contentMode: .fit) // アスペクト比を維持し、指定した幅に収まるようにします
            .frame(width: 300)
        
        /*
        Image(uiImage: lineImage)
            .resizable()
            .rotationEffect(.degrees(90))
            .aspectRatio(contentMode: .fit) // アスペクト比を維持し、指定した幅に収まるようにします
            .frame(width: 380)
            .opacity(0.8)
         */
        /*
        ProgressView(value: Float16(result.count)/30)
                        .progressViewStyle(VerticalProgressViewStyle())
        Spacer().frame(width: 20)
         */
        VStack{
            Text(result.alertInfo.obj)
                .font(.system(size: 20))
            Text(result.alertInfo.line)
                .font(.system(size: 20))
            Text(result.alertInfo.alert)
                .font(.system(size: 20))
            Text(result.alertInfo.count)
                .font(.system(size: 10))
            Text(result.lineAlert)
                .font(.system(size: 10))
            Spacer().frame(height: 10)
            Text(result.objectAlert)
                .font(.system(size: 10))
            Text(result.train)
                .font(.system(size: 10))
        }
    }
}
