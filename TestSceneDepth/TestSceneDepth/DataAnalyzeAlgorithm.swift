//
//  DataAnalyzeAlgorithm.swift
//  TestSceneDepth
//
//  Created by Shirai on 2023/11/20.
//

import Foundation
import opencv2
import Vision
import AudioToolbox

import AVFoundation //追加①AVFoundationをインポート


class DataAnalyzeAlgorithm{
    
    private var depthData: [[Float32]] = []
    private var lines: [[Point]] = []
    private var objects: [(label: String, box:CGRect, conf:VNConfidence)] = []
    static private var count = 0
    static var score = 0
    private let margin = 5
    static let audioAlert = AudioManager(fileName: "Alert")
    static let audioklaxon = AudioManager(fileName: "klaxon")
    static let buu = AudioManager(fileName: "buu")
    static var str = ""
    static var vib = VibrationViewController()
    
    // 初期化ー必要なデータを持ってくる
    init(depthData: [[Float32]], lines: [[Point]], objects: [(String, CGRect, VNConfidence)]) {
        let start = CFAbsoluteTimeGetCurrent()
        // depthData：右上[0][0]、右下[0][256]、左上[192][0]、左下[192][256]
        self.depthData = depthData
        // line.yが画面の横（右0,左192）、line.xが画面の上下(上が0、下が256)
        self.lines = lines
        // (midX,midY): 右上(0,0)、右下(1440,0)、左上(0,1920)、左下(1440,1920)
        self.objects = objects
        DebugTest.debugPrint(String(format:"%0.5f",CFAbsoluteTimeGetCurrent() - start),nl:false)
    }
    
    // ここがメイン関数だと思う、
    public func getInfo(myImage: UIImage,canCapture: Bool) -> (image:UIImage,lineAlert:String,objectAlert:String, alertInfo: (line:String,obj:String,alert:String, count:String), count:Int, train:String) {
        var train = "safe"  // 電車の状況
        let start = CFAbsoluteTimeGetCurrent()      // 時間
        let lineAlert = calDistaceToLine()          // 段差の危険判断
        let objectAlert = calDistaceToObject()      // 障害物の危険判断
        if canCapture == true {
            saveRawDepthData()
            UIImageWriteToSavedPhotosAlbum(myImage, nil, nil, nil)
        }
        let alertInfo = callAlert(line:lineAlert, object: objectAlert)
        //callAlert(line: lineAlert.distance, object: objectAlert.distance, linePosition: lineAlert.position, objectPosition: objectAlert.position, obstacle:objectAlert.obstacle)
        if !lines.isEmpty{      // 段差が発見していないとバグるから、それの対策
//        if true{
            train = checkTrain()    // 列車の位置から危険判断
        }
//        print(String(format:"DAA:%0.5f",CFAbsoluteTimeGetCurrent() - start))
        DebugTest.debugPrint(String(format:"%0.5f",CFAbsoluteTimeGetCurrent() - start))
        return (myImage, lineAlert.str, objectAlert.str, alertInfo, DataAnalyzeAlgorithm.count, train)
    }

    //depthData.count= 192, depthData[0].count=256
    public func checkTrain() -> String{
        let dis_th:Float = 1.5
        var str = Float(99.0)
        
        for object in objects {
            let detectObjectList = ["train","clock"]    // clockは研究室でテストするときに使ってた
            //print(objects)
            if detectObjectList.contains(object.label)  {   // 指定した障害物が検出されているか確認
                // 障害物の位置を正規化する、countは多分それぞれの要素数
                let x = object.box.midY/1920.0*CGFloat(depthData[0].count)  // 左右 255 ~ 0
                let y = object.box.midX/1440.0*CGFloat(depthData.count)  // 上下 0 ~ 191
                // xが高さ（上が０）、
                
//                UIImpactFeedbackGenerator(style: .light).impactOccurred()
//                print("距離:",depthData[Int(y)][Int(x)])
                // 位置と距離を初期化
                var distance = Float32(99.9)
                var point = lines[0]
                
                // 一番近い段差を探す
                for line in lines {
                    var minValue = minDistanceAround(x:Int(line[0].x), y:Int(line[0].y))
                    // point.yが画面の横（右0,左192）、point.xが画面の上下(上が0、下が256)
                    //print(String(format: "(%d,%d), (%d,%d)", Int(point[0].x),Int(point[0].y),Int(point[1].x),Int(point[1].y)))
                    //print(minValue)
                    // 一番近い段差を検出
                    if minValue < distance {
                        distance = minValue
                        // 位置は
                        point = line
                    }
                }
                // 段差の傾きが0 or 無限 ではないか確認
                if (point[0].x != point[1].x && point[0].y != point[1].y){
                    let m = (point[0].y - point[1].y) / (point[0].x - point[1].x)
                    
                    if m != 0{
                        let x_line: Int = Int((Int32(y) - point[0].y) / m + point[0].x)
                        print(m,x_line)
                        // ここで x_line を使用
                        if x_line > Int(x) && x_line < depthData[0].count{
                            var minValue = minDistanceAround(x:Int(x_line), y:Int(y))
                            //print("a距離",String(format:"物体%.3f 段差%.3f 差%.3f",depthData[Int(y)][Int(x)],minValue,depthData[Int(y)][Int(x)]-minValue))
                            str = depthData[Int(y)][Int(x)]-minValue
                            if depthData[Int(y)][Int(x)]-minValue > dis_th {
                                AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(kSystemSoundID_Vibrate)) {}
                                if !DataAnalyzeAlgorithm.buu.isPlaying() {
                                    DataAnalyzeAlgorithm.buu.playSound()
                                }
                            }
                        }
                    }
                // 段差が縦？横？に水平の場合、傾きを求めるときに分母が0になるため、その対策
                    // point[0].x と point[1].x が等しい場合の処理
                    // 例えば、x_line に point[0].x を直接使用する
                } else if(point[0].x == point[1].x) {
                    var minValue = minDistanceAround(x:Int(x), y:Int(y))
                    //print("b距離",String(format:"物体%.3f 段差%.3f 差%.3f",depthData[Int(y)][Int(x)],minValue,depthData[Int(y)][Int(x)]-minValue))
                    str = depthData[Int(y)][Int(x)]-minValue
                    if depthData[Int(y)][Int(x)]-minValue > dis_th {
                        AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(kSystemSoundID_Vibrate)) {}
                        if !DataAnalyzeAlgorithm.buu.isPlaying() {
                            DataAnalyzeAlgorithm.buu.playSound()
                        }
                    }
                }else{      // これはよくわからん
                    print(String(format: "(%d,%d), (%d,%d)", point[0].x,point[0].y,point[1].x,point[1].y))
                }
            }
        }
        return String(format:"%.2f m",str)
    }

    // 障害物の危険判断
    public func calDistaceToObject() -> (str: String, distance:Float32, position:(x:CGFloat,y:CGFloat), obstacle: Bool) {
        var str = "safe"
        var distance = Float32(99.9)
        var position = (CGFloat(0),CGFloat(0))
        
        let detectObjectList = ["person","bench","chair", "bottle","backpack"]      // 障害物のリスト
        //print(objects)
        var obstacle = false
        for object in objects {
            if detectObjectList.contains(object.label) {    // 障害物が検出物のリストに入っているか
                do{
                    // object.box.midXが上下で0~1440, 左右がYで1920~0
                    
                    // 正規化かつ障害物の中心点を取得
                    // print("aaaa",depthData.count, depthData[0].count)   192 256
                    // (midX,midY): 右上(0,0)、右下(1440,0)、左上(0,1920)、左下(1440,1920)
                    let x = object.box.midY/1920.0*CGFloat(depthData.count)     // 0(右)~191(左)
                    let y = object.box.midX/1440.0*CGFloat(depthData[0].count)  // 0(上)~255(下)
                    
                    // depthData：右上[0][0]、右下[0][256]、左上[192][0]、左下[192][256]
                    //print(String(format: "%d,%d", Int(x),Int(y)))
                    
                    // 障害物までの距離を取得
                    let depth = depthData[Int(x)][Int(y)]
                    //print(String(format: "%.3f, %d,%d", depth,Int(x),Int(y)))
                    //calAngle(x_base: 0, y_base: 0, x: -x+w, y: y-h)
                    // オブジェクトのうち、2m 以内　かつ　一番近い障害物を検知する。
                    // 距離から危険かどうかを判断
                    if depth < 2 {
                        str = object.label + ":" + String(format: "%.3f", depth) + "m"
                        if depth < distance {
                            distance = depth
                            position = (x,y)
                            // Y 1820
                        }
                        // 危険物があるよっていうフラグを立てる
                        obstacle = true
                    }
                }catch{
                    
                }
            }
        }
        return (str,distance,position,obstacle)
    }
    
    // 段差が危険か判断
    public func calDistaceToLine() -> (str: String, distance:Float32, position: (x:CGFloat,y:CGFloat)) {
        // points[0][0] close , point[0][1] far
        var str = "safe"
        var distance = Float32(99.9)
        var position = (CGFloat(0),CGFloat(0))
//        print(depthData.count, depthData[0].count) 192 256
        for point in lines {
            var minValue = minDistanceAround(x:Int(point[0].x), y:Int(point[0].y))
            // point.yが画面の横（右0,左192）、point.xが画面の上下(上が0、下が256)
            //print(String(format: "(%d,%d), (%d,%d)", Int(point[0].x),Int(point[0].y),Int(point[1].x),Int(point[1].y)))
            //print(minValue)
            // 一番近い段差を検出
            
            if minValue < 2 {
                str = String(format: "%.3f", minValue) + "m"
                if minValue < distance {
                    distance = minValue
                    // 位置は
                    position = (CGFloat((point[0].y+point[1].y)/2),CGFloat((point[0].x+point[1].x)/2))
                }
            }
        }
        return (str,distance, position)
    }
    
    // 情報から危険値などを決める
    public func callAlert(line:(str: String, distance:Float32, position: (x:CGFloat,y:CGFloat)),object:(str: String, distance:Float32, position:(x:CGFloat,y:CGFloat), obstacle: Bool)) -> (line: String,obj:String,alert:String, count:String) {
        let max = 30
        var level = "なし"
        
        let w = CGFloat(depthData.count/2)
        let h = CGFloat(depthData[0].count-1)
        
        // これの場合、段差までの距離が1m未満なら、count+=3（累積危険値）とする、またアラームの音などを設定している
        if line.distance<1.0{
            level = "段差high"
            //print("aaa",line)
            DataAnalyzeAlgorithm.count+=3
            //DataAnalyzeAlgorithm.audioAlert.changePan(pan: -Float((linePosition-192.0/2)/(192.0/2)))
            DataAnalyzeAlgorithm.audioAlert.changePan(pan: calAngle(x_base: 0, y_base: 0, x: -line.position.x+w, y: line.position.y-h))
            DataAnalyzeAlgorithm.audioAlert.changeVol(vol: Float((2-line.distance)/2+0.5))
        // これの場合、障害物があり、なおかつ、その距離が1m未満なら累積危険値を+2
        } else if object.distance<1 && object.obstacle == true {
            //print("ccc",object)
            level = "障害物high"
//            print(objectPosition)
            DataAnalyzeAlgorithm.count+=2
            //DataAnalyzeAlgorithm.audioAlert.changePan(pan: -Float((objectPosition-1920.0/2)/(1920.0/2)))
            DataAnalyzeAlgorithm.audioklaxon.changePan(pan: calAngle(x_base: 0, y_base: 0, x: -object.position.x+w, y: object.position.y-h))
            DataAnalyzeAlgorithm.audioklaxon.changeVol(vol: Float((2-object.distance)/2))
        } else if line.distance<1.5 {
            //print("bbb",line)
            level = "段差low"
            DataAnalyzeAlgorithm.count+=1
            //DataAnalyzeAlgorithm.audioAlert.changePan(pan: -Float((linePosition-192.0/2)/(192.0/2)))
            DataAnalyzeAlgorithm.audioAlert.changePan(pan: calAngle(x_base: 0, y_base: 0, x: -line.position.x+w, y: line.position.y-h))
            DataAnalyzeAlgorithm.audioAlert.changeVol(vol: Float((2-line.distance)/2+0.5))
        } else if object.distance<2 && object.obstacle == true {
            //print("ddd",object)
            level = "障害物low"
//            print(objectPosition)
            DataAnalyzeAlgorithm.count+=1
            //DataAnalyzeAlgorithm.audioAlert.changePan(pan: -Float((objectPosition-1920.0/2)/(1920.0/2)))
            DataAnalyzeAlgorithm.audioklaxon.changePan(pan: calAngle(x_base: 0, y_base: 0, x: -object.position.x+w, y: object.position.y-h))
            DataAnalyzeAlgorithm.audioklaxon.changeVol(vol: Float((2-object.distance)/2))
        } else {
            //print("eee",line, object)
            DataAnalyzeAlgorithm.count-=1
        }

        // 累積危険値の上限や下限のための処理
        if DataAnalyzeAlgorithm.count > max {
            DataAnalyzeAlgorithm.count = max
        }else if DataAnalyzeAlgorithm.count < 0 {
            DataAnalyzeAlgorithm.count = 0
        }
        // 警告を鳴らす
        if DataAnalyzeAlgorithm.count>20 {
            /*
            if !audioManager.isPlaying() {
                audioManager.playSound()
            }
             */
            if level.prefix(2) == "段差"{
                if !DataAnalyzeAlgorithm.audioAlert.isPlaying() {
                    DataAnalyzeAlgorithm.audioAlert.playSound()
                    DataAnalyzeAlgorithm.str = DataAnalyzeAlgorithm.audioAlert.getInfo()
                }
            } else if level.prefix(2) == "障害"{
                if !DataAnalyzeAlgorithm.audioAlert.isPlaying() && !DataAnalyzeAlgorithm.audioklaxon.isPlaying() {
                    DataAnalyzeAlgorithm.audioklaxon.playSound()
                    DataAnalyzeAlgorithm.str = DataAnalyzeAlgorithm.audioklaxon.getInfo()
                }
            }
        }
        var lp_s = ""
        var op_s = ""
        // この辺はアプリに情報を表示するためのやつ
        //let lp = -Float((linePosition-192.0/2)/(192.0/2))
        let lp = -calAngle(x_base: 0, y_base: 0, x: -line.position.x+w, y: line.position.y-h)
        if lp > 0 {
            lp_s = "段差: " + String(format: "右:%.0f, 距離:%.2f", abs(lp*90), line.distance)
        } else if lp < 0 {
            lp_s = "段差: " + String(format: "左:%.0f, 距離:%.2f", abs(lp*90), line.distance)
        } else {
            lp_s = "段差: " + String(format: "正面, 距離:%.2f", line.distance)
        }
        let op = -calAngle(x_base: 0, y_base: 0, x: -object.position.x+w, y: object.position.y-h)
        
        if op > 0 {
            op_s = "障害物: " + String(format: "右:%.0f, 距離:%.2f", abs(op*90), object.distance)
        } else if op < 0 {
            op_s = "障害物: " + String(format: "左:%.0f, 距離:%.2f", abs(op*90), object.distance)
        } else {
            op_s = "障害物: " + String(format: "正面, 距離:%.2f", object.distance)
        }
        return (lp_s,op_s, DataAnalyzeAlgorithm.str, level + ", " + String(DataAnalyzeAlgorithm.count))
        //String(lp) + ", " + String(op) + "\n" + DataAnalyzeAlgorithm.str + "\n" + String(DataAnalyzeAlgorithm.count)
    }
    
    // 角度計算、電車の場所の判断のために使っている（）
    func calAngle(x_base: CGFloat, y_base:CGFloat, x:CGFloat, y:CGFloat) -> Float{
        var angle = Float(0)
        if x_base - x != 0{
            let theta = atan(Float(y_base - y) / Float(x_base - x)) * 180.0 / Float.pi
            if theta > 0 {
                angle = 1-abs(theta/90)
            } else if theta < 0 {
                angle = -1+abs(theta/90)
            }
        }
        return angle
    }
    
    // ある点の周辺をみて、一番距離が近い点の距離情報を返す
    func minDistanceAround(x:Int, y:Int) -> Float32 {
        var minValue = depthData[y][x]
        let ue = depthData[max(y - margin, 0)][x]
        let sita = depthData[min(y + margin, depthData.count-1)][x]
        let hidari = depthData[y][max(x - margin, 0)]
        let migi = depthData[y][min(x + margin, depthData[0].count-1)]
        minValue = min(minValue, min(ue, min(sita, min(hidari,migi))))
        return minValue
    }
    
    // csvファイルに距離情報を書き込み、保存
    public func saveRawDepthData() {
        
        let now = Date()

        // DateFormatter のインスタンスを作成
        let formatter = DateFormatter()

        // フォーマットを設定（例: "yyyy-MM-dd HH:mm:ss"）
        formatter.dateFormat = "yyyy-MM-dd HH：mm：ss：SSS"

        // 日時を String に変換
        let dateString = formatter.string(from: now)
        
        // CSV形式の文字列を生成する
        var csvString = ""
        for row in depthData {
            let rowString = row.map { String($0) }.joined(separator: ",")
            csvString += rowString + "\n"
        }

        // ファイルに書き込む
        let fileManager = FileManager.default
        guard let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("ドキュメントディレクトリの取得エラー")
            return
        }

        let filePath = documentDirectory.appendingPathComponent("DepthData(" + dateString + ".csv")

        // CSV文字列をファイルに書き込み
        do {
            try csvString.write(to: filePath, atomically: true, encoding: .utf8)
            print("CSVファイル保存: \(filePath)")
        } catch {
            print("CSVファイル書き込みエラー: \(error)")
        }
    }
    
    /*
    /*
    public func calDistaceToLine() -> (str: String, distance:Float32, position: CGFloat) {
        // points[0][0] close , point[0][1] far
        var str = "safe"
        var distance = Float32(99.9)
        var position = CGFloat(0)
//        print(depthData.count, depthData[0].count) 192 256
        for point in lines {
            /*
            var minValue = depthData[Int(point[0].y)][Int(point[0].x)]
            let ue = depthData[max(Int(point[0].y) - margin, 0)][Int(point[0].x)]
            let sita = depthData[min(Int(point[0].y) + margin, depthData.count-1)][Int(point[0].x)]
            let hidari = depthData[Int(point[0].y)][max(Int(point[0].x) - margin, 0)]
            let migi = depthData[Int(point[0].y)][min(Int(point[0].x) + margin, depthData[0].count-1)]
            minValue = min(minValue, min(ue, min(sita, min(hidari,migi))))
            */
            var minValue = minDistanceAround(x:Int(point[0].x), y:Int(point[0].y))
            // point.yが画面の横（右0,左192）、point.xが画面の上下(上が0、下が256)
            //print(String(format: "(%d,%d), (%d,%d)", Int(point[0].x),Int(point[0].y),Int(point[1].x),Int(point[1].y)))
            //print(minValue)
            // 一番近い段差を検出
            if minValue < 2 {
                str = String(format: "%.3f", minValue) + "m"
                if minValue < distance {
                    distance = minValue
                    // 位置は
                    position = CGFloat((point[0].y+point[1].y)/2)
                }
            }
        }
        return (str,distance, position)
    }
    */
    
    /*
    
    
    
    public func calDistaceToObject() -> (str: String, distance:Float32, position: CGFloat,obstacle: Bool) {
        var str = "safe"
        var distance = Float32(99.9)
        var position = CGFloat(0)
        let w = CGFloat(192/2)
        let h = CGFloat(256-1)
        
        let detectObjectList = ["person", "clock","bench","chair","laptop"]
        //print(objects)
        var obstacle = false
        for object in objects {
            if detectObjectList.contains(object.label) {
                do{
                    // object.box.midXが上下で0~1440, 左右がYで1920~0
                    
                    // print("aaaa",depthData.count, depthData[0].count)   192 256
                    // (midX,midY): 右上(0,0)、右下(1440,0)、左上(0,1920)、左下(1440,1920)
                    let x = object.box.midY/1920.0*CGFloat(depthData.count)     // 0(右)~191(左)
                    let y = object.box.midX/1440.0*CGFloat(depthData[0].count)  // 0(上)~255(下)
                    
                    // depthData：右上[0][0]、右下[0][256]、左上[192][0]、左下[192][256]
                    //print(String(format: "%d,%d", Int(x),Int(y)))
                    
                    let depth = depthData[Int(x)][Int(y)]
                    //print(String(format: "%.3f, %d,%d", depth,Int(x),Int(y)))
                    calAngle(x_base: 0, y_base: 0, x: -x+w, y: y-h)
                    // オブジェクトのうち、2m 以内　かつ　一番近い障害物を検知する。
                    if depth < 2 {
                        str = object.label + ":" + String(format: "%.3f", depth) + "m"
                        if depth < distance {
                            distance = depth
                            position = object.box.midY
                            // Y 1820
                        }
                        obstacle = true
                    }
                }catch{
                    
                }
            }
        }
        return (str,distance,position,obstacle)
    }
    */
    
    /*
     public func callAlert(line:Float32, object:Float32, linePosition: CGFloat, objectPosition: (x:CGFloat,y:CGFloat),obstacle: Bool) -> (dis:String,alert:String, count:String) {
         let max = 30
         var level = "なし"
         
         let w = CGFloat(depthData.count/2)
         let h = CGFloat(depthData[0].count-1)
         
         if line<1{
             level = "段差high"
             //print("aaa",line)
             DataAnalyzeAlgorithm.count+=2
             DataAnalyzeAlgorithm.audioAlert.changePan(pan: -Float((linePosition-192.0/2)/(192.0/2)))
             DataAnalyzeAlgorithm.audioAlert.changeVol(vol: Float((2-line)/2+0.5))
         } else if object<1 && obstacle == true {
             //print("ccc",object)
             level = "障害物high"
 //            print(objectPosition)
             DataAnalyzeAlgorithm.count+=2
             //DataAnalyzeAlgorithm.audioAlert.changePan(pan: -Float((objectPosition-1920.0/2)/(1920.0/2)))
             DataAnalyzeAlgorithm.audioAlert.changePan(pan: calAngle(x_base: 0, y_base: 0, x: -objectPosition.x+w, y: objectPosition.y-h))
             DataAnalyzeAlgorithm.audioAlert.changeVol(vol: Float((2-object)/2+0.5))
         } else if line<2 {
             //print("bbb",line)
             level = "段差low"
             DataAnalyzeAlgorithm.count+=1
             DataAnalyzeAlgorithm.audioAlert.changePan(pan: -Float((linePosition-192.0/2)/(192.0/2)))
             DataAnalyzeAlgorithm.audioAlert.changeVol(vol: Float((2-line)/2+0.5))
         } else if object<2 && obstacle == true {
             //print("ddd",object)
             level = "障害物low"
 //            print(objectPosition)
             DataAnalyzeAlgorithm.count+=1
             //DataAnalyzeAlgorithm.audioAlert.changePan(pan: -Float((objectPosition-1920.0/2)/(1920.0/2)))
             DataAnalyzeAlgorithm.audioAlert.changePan(pan: calAngle(x_base: 0, y_base: 0, x: -objectPosition.x+w, y: objectPosition.y-h))
             DataAnalyzeAlgorithm.audioAlert.changeVol(vol: Float((2-object)/2+0.5))
         } else {
             //print("eee",line, object)
             DataAnalyzeAlgorithm.count-=1
         }
         if DataAnalyzeAlgorithm.count > max {
             DataAnalyzeAlgorithm.count = max
         }else if DataAnalyzeAlgorithm.count < 0 {
             DataAnalyzeAlgorithm.count = 0
         }
         if DataAnalyzeAlgorithm.count>20 {
             /*
             if !audioManager.isPlaying() {
                 audioManager.playSound()
             }
              */
             if !DataAnalyzeAlgorithm.audioAlert.isPlaying() {
                 DataAnalyzeAlgorithm.audioAlert.playSound()
                 DataAnalyzeAlgorithm.str = DataAnalyzeAlgorithm.audioAlert.getInfo()
             }
         }
         var lp_s = ""
         var op_s = ""
         let lp = -Float((linePosition-192.0/2)/(192.0/2))
         if lp > 0 {
             lp_s = "段差: 右" + String(format: "%.3f", abs(-Float((linePosition-192.0/2)/(192.0/2))))
         } else if lp < 0{
             lp_s = "段差: 左" + String(format: "%.3f", abs(-Float((linePosition-192.0/2)/(192.0/2))))
         } else {
             lp_s = "段差: 正面"
         }
         let op = -calAngle(x_base: 0, y_base: 0, x: -objectPosition.x+w, y: objectPosition.y-h)
         
         if op > 0 {
             op_s = "障害物: 右" + String(format: "%.3f", abs(op))
         } else if op < 0{
             op_s = "障害物: 左" + String(format: "%.3f", abs(op))
         } else {
             op_s = "障害物: 正面"
         }
         return (lp_s + ",       " + op_s, DataAnalyzeAlgorithm.str, level + ", " + String(DataAnalyzeAlgorithm.count))
         //String(lp) + ", " + String(op) + "\n" + DataAnalyzeAlgorithm.str + "\n" + String(DataAnalyzeAlgorithm.count)
     }
     */
     
     */
}
