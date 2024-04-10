//
//  ARSessionManager.swift
//  TestSceneDepth
//
//  Created by Shirai on 2023/06/19.
//

import Foundation
import ARKit
import RealityKit


/*
距離情報やRGB画像を取得するためのクラス
NSObject: SwiftとObjective-Cを繋ぐ架け橋、らしい、あまり意識してない、Core Dataを扱う際に必要らしい
ARSessionDelegate: ARKitフレームワークにおいて、ARSessionオブジェクトからのイベントを受け取るためのプロトコル
    プロトコル：こういうのは実装しましょうねっていう決まり事みたいなやつ
ObservableObject: SwiftUIでデータの変更を監視し、データが変わるとUIを自動的に更新する役割を持つプロトコル
    ボタンを押して数値が変わる⇨画面更新みたいな？あんまわからん
*/
class ARSessionManager: NSObject, ARSessionDelegate, ObservableObject {
    var arSession = ARSession()                 // ARデータ（LiDARなど）を取得するための公式クラス
    @Published var arData = ARData()            // ARデータを取得する自作クラス
    @Published var distance: Float32 = 0.0      // なんだろこれ　多分使ってない変数、テスト段階で使った？
    @Published var confidence: UInt8 = 0        // これも同じ
    var startTime: Date = Date()                // これも多分処理速度の検証のため
    
    
    // 初期化するための変数
    override init(){
        super.init()
        arSession.delegate = self
        startSession()
    }
    
    // ARSessionの初期化的な
    func startSession(){
        let config = ARWorldTrackingConfiguration()     // なんだっけこれ
        config.frameSemantics.insert([.sceneDepth, .smoothedSceneDepth])    // 取得するデータのタイプを取得
        arSession.run(config)   // データ取得開始
    }
    
    // 取得停止
    func pauseSession(){
        arSession.pause()
    }
    
    
    
    func getDistance() -> Float32 {
        return distance
    }
    
    func getConfidence() -> UInt8 {
        return confidence
    }
    
     
    func getARData() -> ARData {
        return arData
    }
    
    // データを配列に格納するための関数
    func calDistance(pixelBuffer: CVPixelBuffer) {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        
        let base = CVPixelBufferGetBaseAddress(pixelBuffer)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        // 真ん中の座標を指定
        let x = Int(width/2)
        let y = Int(height/2)
        
        
        let bindPtr = base?.bindMemory(to: Float32.self, capacity: width * height)
        
        let bufPtr = UnsafeBufferPointer(start: bindPtr, count: width * height)
        
        let depthArray = Array(bufPtr)
        
        let fixedArray = depthArray.map({$0.isNaN ? 0 : $0})
        distance = fixedArray[width*y + x]
    }
    
    // 信頼度を計算してるらしい
    func calConfidence(pixelBuffer: CVPixelBuffer) {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        
        let base = CVPixelBufferGetBaseAddress(pixelBuffer)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        let x = Int(width/2)
        let y = Int(height/2)
        
        let bindPtr = base?.bindMemory(to: UInt8.self, capacity: width * height)
        
        let bufPtr = UnsafeBufferPointer(start: bindPtr, count: width * height)
        
        let depthArray = Array(bufPtr)
        
        confidence = depthArray[width*y + x]
        
    }
    

    // これが何回も実行されてる、はず
    // ARFrameに取得したデータが入ってくる
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
//        guard frame.sceneDepth?.depthMap != nil, frame.sceneDepth?.confidenceMap != nil,frame.capturedImage != nil, frame.smoothedSceneDepth?.depthMap != nil, frame.smoothedSceneDepth?.confidenceMap != nil else {return}
        // データが正しく取得されているか
        guard frame.sceneDepth?.depthMap != nil, frame.capturedImage != nil, frame.smoothedSceneDepth?.depthMap != nil else {return}
        
        // データを格納する
        
        arData.depthMap = frame.sceneDepth?.depthMap
        
        arData.confidenceMap = frame.sceneDepth?.confidenceMap
        arData.capturedImage = frame.capturedImage
//        arData.smoothedDepthMap = frame.smoothedSceneDepth?.depthMap
//        arData.smoothedConfidenceMap = frame.smoothedSceneDepth?.confidenceMap
        //arData.depthMapUIImage = frame.sceneDepth?.depthMap.convertToUIImage()
        //arData.confidenceMapUIImage = frame.sceneDepth?.confidenceMap?.convertToUIImage()
        calDistance(pixelBuffer: arData.depthMap!)  
//        calConfidence(pixelBuffer: arData.confidenceMap!)
        //print("")
        
//        print("debug: \(String(format: "%.5f", Date().timeIntervalSince(startTime)))")
//        startTime = Date()
        
    }
    
    
    
}
