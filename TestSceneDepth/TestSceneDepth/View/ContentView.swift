import SwiftUI
import ARKit

// 距離情報：256,192（横縦）
// 深度画像：256,192（横縦）

// 起動したときに呼び出されるようなやつ
// ビューといいながら、関数のように使っている場合もある
struct ContentView : View {
    
    @ObservedObject var arSessionManager = ARSessionManager()
    
    @State var selectView = 0                   // 使ってないかも
    @State var selectView2 = 0                  // これも使ってないかも
    @State var maxDistance: Float = 0.5         // 段差距離
    @State var opacity: Double = 7.0            // 有効距離、透明度
    @State var showError: Bool = false          // 有効距離外のデータの色を変える？？
    @State var canCapture: Bool = false         // データを保存するための変数
    @State var isSmoothed: Bool = false         // 平均化されたデータを使う
    @State var showDistance: Bool = false       // 検出した線分の距離を表示
    
    @State var th1 = 50                 // Canny関数の閾値1
    @State var th2 = 120                // Canny関数の閾値2
    
    
    @State var line_th = 65             // 線分検出の値
    @State var length = 25
    @State var gap = 20
    
    @State var cover = false        // 使ってない
    @State var showMode = 1         // 表示するモード（線分検出、物体検出、実証モード）
    @State var selectImage1 = 0     // 
    @State var selectImage2 = 0     // 
    
    @State var yoloModel = try? VNCoreMLModel(for: yolov8s().model)     // 物体検出モデル
    
    
    var audioManager = AudioManager(fileName: "Alert")      // 音を鳴らす
    
    var body: some View {
        VStack{
            // 線分検出の処理
            if showMode == 1 {
                // 設定のビュー？を出す
                ShareSettingView(maxDistance: $maxDistance, opacity: $opacity, showError: $showError, canCapture: $canCapture, isSmoothed: $isSmoothed, showDistance: $showDistance, selectView1: $selectView, selectView2: $selectView2, th1: $th1, th2: $th2, line_th: $line_th, length: $length, gap: $gap)
                
                // これも設定のビュー？
                ShowSettingView(showMode: $showMode, selectImage1: $selectImage1, selectImage2: $selectImage2)
                
                // RGB画像
                if selectImage1 == 0{
                    // RGB画像取得
                    let myImage = arSessionManager.getARData().getCapturedUIImage()
                    if canCapture {
                    }
                    if myImage != nil {
                        // 保存する
                        Button(action:{
                            arSessionManager.getARData().saveRawDepthData(isSmoothed: isSmoothed)
                            UIImageWriteToSavedPhotosAlbum(myImage!, self, nil, nil)
                        }){Text("保存")}
                        // 画像表示
                        SingleImageView(myImage: myImage!)
                    } else { Text("エラー または nil 発生") }
                
                // 深度画像
                } else if selectImage1 == 1{
                    // 深度画像取得
                    let myImage = arSessionManager.getARData().getDepthMapUIImage(maxDistance: maxDistance*5, showError: showError, canCapture: canCapture, isSmoothed: isSmoothed)
                    //let myImage = arSessionManager.getARData().getRawDepth(threshold:Float32(maxDistance))
                    if myImage != nil {
                        HStack{
                            // 保存
                            Button(action:{
                                // 音を鳴らす テストでここに実装
                                if !audioManager.isPlaying() {
                                    audioManager.playSound()
                                }
                                // 保存
                                UIImageWriteToSavedPhotosAlbum(myImage!, self, nil, nil)
                            }){Text("保存")}
                            Text(String(maxDistance*5))
                        }
                        SingleImageView(myImage: myImage!)
                    } else { Text("エラー または nil 発生") }
                // エッジ画像
                } else if selectImage1 == 2{
                    // 多分コメントアウトしてる方がエッジ画像の取得だと思う。手元にMacがないんで検証できない
                    //let myImage = arSessionManager.getARData().getEdgeMapUIImage(maxDistance: 5.0,showError: showError, canCapture: canCapture, isSmoothed: isSmoothed, th1: th1, th2:th2)
                    // 深度データを取得
                    let myImage = arSessionManager.getARData().getRawDepth(threshold:Float32(maxDistance), opacity:opacity)
                    if myImage != nil {
                        Button(action:{
                            if !audioManager.isPlaying() {
                                audioManager.playSound()
                            }
                            UIImageWriteToSavedPhotosAlbum(myImage!, self, nil, nil)
                        }){Text("保存")}
                        SingleImageView(myImage: myImage!)
                    } else { Text("エラー または nil 発生") }
                // 直線画像
                } else if selectImage1 == 3 {
                    //let myImage = arSessionManager.getARData().getLineMapUIImage(maxDistance: maxDistance,showError: showError, canCapture: canCapture, isSmoothed: isSmoothed, th1: th1, th2:th2, line_th: line_th, length: length, gap: gap, showDistance: showDistance)
                    let myImage = arSessionManager.getARData().getColorLineUIImage(maxDistance: maxDistance,line_th: line_th, length: length, gap: gap, opacity: opacity)
                    if myImage != nil {
                        Button(action:{
                            if !audioManager.isPlaying() {
                                audioManager.playSound()
                            }
                            UIImageWriteToSavedPhotosAlbum(myImage!, self, nil, nil)
                        }){Text("保存")}
                        SingleImageView(myImage: myImage!)
                    } else { Text("エラー または nil 発生") }
                // カラーエッジ画像　これは遊び
                } else if selectImage1 == 4 {
                    let myImage = arSessionManager.getARData().getCapturedEdgeUIImage()
                    if myImage != nil {
                        Button(action:{
                            if !audioManager.isPlaying() {
                                audioManager.playSound()
                            }
                            UIImageWriteToSavedPhotosAlbum(myImage!, self, nil, nil)
                        }){Text("保存")}
                        SingleImageView(myImage: myImage!)
                    } else { Text("エラー または nil 発生") }
                // 重なり、このした3つはあんまり関係ない、過去の遺物
                } else if selectImage1 == 5 {
                    /*
                     let myImage1 = arSessionManager.getARData().getCapturedUIImage()
                     let myImage2 = arSessionManager.getARData().getLineMapUIImage(maxDistance: maxDistance,showError: showError, canCapture: canCapture, isSmoothed: isSmoothed, th1: th1, th2:th2, line_th: line_th, length: length, gap: gap, showDistance: showDistance)
                     if myImage1 != nil && myImage2 != nil {
                     OverlapImageView(myImage1: myImage1!, myImage2: myImage2!, opacity: opacity)
                     } else { Text("エラー または nil 発生") }
                     */
                    
                    let myImage = arSessionManager.getARData().getConfMapUIImage()
                    //let myImage = arSessionManager.getARData().getRawDepth(threshold:Float32(maxDistance))
                    if myImage != nil {
                        Button(action:{
                            if !audioManager.isPlaying() {
                                audioManager.playSound()
                            }
                            UIImageWriteToSavedPhotosAlbum(myImage!, self, nil, nil)
                        }){Text("保存")}
                        SingleImageView(myImage: myImage!)
                    } else { Text("エラー または nil 発生") }
                } else if selectImage1 == 6 {
                    let myImage1 = arSessionManager.getARData().getDepthMapUIImage(maxDistance: maxDistance*5, showError: showError, canCapture: canCapture, isSmoothed: isSmoothed)
                    let myImage2 = arSessionManager.getARData().getLineMapUIImage(maxDistance: maxDistance,showError: showError, canCapture: canCapture, isSmoothed: isSmoothed, th1: th1, th2:th2, line_th: line_th, length: length, gap: gap, showDistance: showDistance)
                    if myImage1 != nil && myImage2 != nil {
                        OverlapImageView(myImage1: myImage1!, myImage2: myImage2!, opacity: opacity)
                    } else { Text("エラー または nil 発生") }
                } else if selectImage1 == 7 {
                    let myImage1 = arSessionManager.getARData().getCapturedUIImage()
                    let myImage2 = arSessionManager.getARData().getLineMapUIImage(maxDistance: maxDistance,showError: showError, canCapture: canCapture, isSmoothed: isSmoothed, th1: th1, th2:th2, line_th: line_th, length: length, gap: gap, showDistance: showDistance)
                    if myImage1 != nil && myImage2 != nil {
                        OverlapImageView(myImage1: myImage1!, myImage2: myImage2!, opacity: 0.5)
                    } else { Text("エラー または nil 発生") }
                } else { Text("知らない") }
            // 物体検出モード
            } else if showMode == 2{
                // モード切替ビュー
                ShowSettingView(showMode: $showMode, selectImage1: $selectImage1, selectImage2: $selectImage2)
                let myImage = arSessionManager.getARData().getCapturedUIImage()
                if myImage != nil {
                    // 物体検出ビュー
                    DetectImageView(myImage: myImage!, yoloModel: $yoloModel)
                } else { Text("エラー または nil 発生") }
            // 実証（組み合わせ）モード
            } else if showMode == 3{
                //all:0.06691 col: 0.00462 Depth:0.01111 Line0.01548 obj:0.02230 DAA:0.00002
                ShowSettingView(showMode: $showMode, selectImage1: $selectImage1, selectImage2: $selectImage2)
                //                let lineImage = arSessionManager.getARData().getLineMapUIImage(maxDistance: maxDistance,showError: showError, canCapture: canCapture, isSmoothed: isSmoothed, th1: th1, th2:th2, line_th: line_th, length: length, gap: gap, showDistance: showDistance)
                let colorImage = arSessionManager.getARData().getCapturedUIImage()                  // RGB画像
                let depthData = arSessionManager.getARData().getDepthData()                         // 深度データ
                let lines = arSessionManager.getARData().getLinePoints(maxDistance: maxDistance,line_th: line_th, length: length, gap: gap)     // 段差線分の座標
                
                if colorImage != nil {
                    JudgeView(colorImage: colorImage!, yoloModel: $yoloModel,depthData: depthData, lines:lines)     // 判断するためのビュー
                } else { Text("エラー または nil 発生") }
            // テストのためのビュー
            }else if showMode == 4{
                ShowSettingView(showMode: $showMode, selectImage1: $selectImage1, selectImage2: $selectImage2)
                TestView()
            }
            Spacer()
        }
    }
}


struct CustomView: View {
    @Binding var distance: Float32
    
    var body: some View {
        Text("Distance \(distance)")
    }
}
