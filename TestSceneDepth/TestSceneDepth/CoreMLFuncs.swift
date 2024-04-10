//
//  CoreMLFincs.swift
//  OpenCVTestApp
//
//  Created by Shirai on 2023/08/10.
//

// CoreMLの関数をまとめたファイル


import Foundation
import SwiftUI
import CoreML
import Vision

import AVFoundation //追加①AVFoundationをインポート

class CoreMLFuncs:ObservableObject {
    @State private var currentInd = 1
    
    //[[(String, CGRect, VNConfidence)]]
    // 予測関数、画像とモデルを引数とし、検出結果の画像と検出結果の情報を返す
    static func predict(image: UIImage, yolo: VNCoreMLModel) -> (img: UIImage, str: String){
        var objectsList = ""
        var img = image.rotateImageLeft90Degrees(image)     // 受け取る画像が回転していたため、戻すためにここで回転
        
        let w_img = img!.getWidth()
        let h_img = img!.getHeight()
        let color = UIColor.red // 四角形の色
        var objectInfo: [[(String, CGRect, VNConfidence)]] = []     // ラベル、バウンディングボックス、信頼度
        
        // この先はいまいち覚えてない

//        DispatchQueue.global(qos: .default) .async{
            // リクエストの生成
        let request = VNCoreMLRequest(model: yolo) {
            request, error in
            //エラー処理
            if error != nil {
                //self.showAlert(error!.localizedDescription)
                return
            }
        }
        request.imageCropAndScaleOption = VNImageCropAndScaleOption.scaleFill
        let ciImage = CIImage(image:img!)!
        
        let orientation = CGImagePropertyOrientation(rawValue: UInt32(img!.imageOrientation.rawValue))!
        
        let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
//            guard (try? handler.perform([request])) != nil else {return}
        try? handler.perform([request])
    
        var objects = (request.results as! [VNRecognizedObjectObservation])
        let context = UIGraphicsGetCurrentContext()
        objects = nonMmaxinumSuppression(objects)
    
        let detectObjectList = ["train", "clock","bench","person","cell phone","laptop", "chair","backpack"]
    
        // img.size: (1920.0, 1440.0)
        for object in objects {
            //print(objects)
            if detectObjectList.contains(object.labels.first!.identifier) {
                //                let rect = convertRect(object.boundingBox, image.size)
                let rect = object.boundingBox
                let label = object.labels.first!.identifier
                let conf = object.labels.first!.confidence
                
                //                print(label, ": ", rect)
                //                print("1", objectsList)
                /*
                 var minX = Int(rect.origin.x*CGFloat(image.getWidth()))
                 var minY = Int((1.0-rect.origin.y)*CGFloat(image.getHeight()))
                 var maxX = Int(rect.size.width*CGFloat(image.getWidth()))
                 var maxY = -Int((rect.size.height)*CGFloat(image.getHeight()))
                 */
                // バウンディングボックスを設定
                let minX = Int(rect.origin.x*CGFloat(w_img))
                let minY = Int((1.0-rect.origin.y)*CGFloat(h_img))
                let width = Int(rect.size.width*CGFloat(w_img))
                let height = -Int((rect.size.height)*CGFloat(h_img))
                // 右上が原点,左回転
                let rectangle = CGRect(x: minX, y: minY, width: width, height: height)
                //let rectangle = convertRect(rect: rect, imgSize: img.size)
                //print(rectangle)
                //                print(minX,", ",minY,", ",maxX,", ",maxY)
                //let rectangle = convertedRect(rect: boundingBox, to: boundingBox.size, width:img!.getWidth(), height:img!.getHeight())
                //print()
                img = CoreMLFuncs().drawRectangleOnImage(image: img!, rectangle: rectangle, color: color, text: label, textPoint: CGPoint(x: rectangle.midX, y: rectangle.midY))!
                
                //let p_str: String = String(format: "[%d, %d,%d, %d]",minX,minY,width+minX,height-minY)
                //objectsList += label + ":" + p_str + String(format: "(%.3f)\n",conf)
                let ss = -Float((rectangle.midX-1440.0/2)/(1440.0/2))
                objectsList += label + ":" + String(format: "[(%.0f,%.0f), (%.0f,%.0f)]%.3f\n",rectangle.minX,rectangle.minY,rectangle.maxX,rectangle.maxY, ss)
                //objectsList += label + ":" + String(format: "[(%d,%d), (%d,%d)",image.getWidth()-minY,minX,image.getWidth()-height+minY,width+minX) + String(format: "(%.3f)", conf) + "\n"
                let exampleElement: (String, CGRect, VNConfidence) = (label, rectangle, conf)
                objectInfo.append([exampleElement])
            }
        }
//        }
        //print("2", objectsList)
        //print(objectsList)
        return (img!, objectsList)   // (256.0, 192.0)
    }
    
    
    // 検出した物体の情報のみを取得
    static func getObjects(image: UIImage, yolo: VNCoreMLModel) -> [(label:String, box:CGRect, conf:VNConfidence)]{
        
        let start = CFAbsoluteTimeGetCurrent()
        var objectsList = ""
        var img = image.rotateImageLeft90Degrees(image)
        
        let w_img = img!.getWidth()
        let h_img = img!.getHeight()
        let color = UIColor.red // 四角形の色
        var objectInfo: [(String, CGRect, VNConfidence)] = []
        
//        DispatchQueue.global(qos: .default) .async{
            // リクエストの生成
            let request = VNCoreMLRequest(model: yolo) {
                request, error in
                //エラー処理
                if error != nil {
                    //self.showAlert(error!.localizedDescription)
                    return
                }
            }
            request.imageCropAndScaleOption = VNImageCropAndScaleOption.scaleFill
            let ciImage = CIImage(image:img!)!
            
            let orientation = CGImagePropertyOrientation(rawValue: UInt32(img!.imageOrientation.rawValue))!
            
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
//            guard (try? handler.perform([request])) != nil else {return}
            try? handler.perform([request])
        
            var objects = (request.results as! [VNRecognizedObjectObservation])
            let context = UIGraphicsGetCurrentContext()
            objects = nonMmaxinumSuppression(objects)
            
        
            
            for object in objects {
//                let rect = convertRect(object.boundingBox, image.size)
                let rect = object.boundingBox
                let label = object.labels.first!.identifier
                let conf = object.labels.first!.confidence
                
//                print(label, ": ", rect)
//                print("1", objectsList)
                
                /*
                print("=======================")
                print("rect: ", rect)
                print("img: ",img.size)
                print("=======================")
                let minX = Int(rect.origin.x*CGFloat(img.getWidth()))
                let minY = Int((1.0-rect.origin.y)*CGFloat(img.getHeight()))
                let maxX = Int(rect.size.width*CGFloat(img.getWidth()))
                let maxY = -Int((rect.size.height)*CGFloat(img.getHeight()))
                let rectangle = CGRect(x: minX, y: minY, width: maxX, height: maxY)
                 */
                //let rectangle = convertRect(rect: rect, imgSize: img.size)
                //print(String(format: "%d]", Int(rectangle.midX)))
        //                print(minX,", ",minY,", ",maxX,", ",maxY)
                //let rectangle = convertedRect(rect: boundingBox, to: boundingBox.size, width:img!.getWidth(), height:img!.getHeight())
                //img = CoreMLFuncs().drawRectangleOnImage(image: img, rectangle: rectangle, color: color, text: label, textPoint: CGPoint(x: rectangle.midX, y: rectangle.midY))!
            
                //objectsList += label + ":" + String(format: "[%d",Int(img.size.height - rectangle.midY)) + "," + String(format: "%d]", Int(rectangle.midX)) + String(format: "(%.3f)", conf) + "\n"
                
                // これはなんだろ、、、原点を変えたのかな
                let minX = Int(rect.origin.x*CGFloat(w_img))
                let minY = Int((1.0-rect.origin.y)*CGFloat(h_img))
                let width = Int(rect.size.width*CGFloat(w_img))
                let height = -Int((rect.size.height)*CGFloat(h_img))
                // 左上が原点
                let rectangle = CGRect(x: minX, y: minY, width: width, height: height)
                let exampleElement: (String, CGRect, VNConfidence) = (label, rectangle, conf)
                objectInfo.append(exampleElement)
            }
//        }
//        print(objectsList)
        
        DebugTest.debugPrint(String(format:"%0.5f",CFAbsoluteTimeGetCurrent() - start), nl: false)
//        print(String(format:"obj:%0.5f",CFAbsoluteTimeGetCurrent() - start), terminator:" ")
        return objectInfo   // (256.0, 192.0)
    }

    // なんだこれ、現状使ってない
    static func convertRect(rect: CGRect, imgSize: CGSize) -> CGRect {
        // Y座標を反転し、maxYを基準にする
        let x = rect.minX * imgSize.width
        let width = rect.width * imgSize.width
        let y = (1-rect.minY)*imgSize.height
        let height = -rect.height * imgSize.height
        
        return CGRect(x: x, y: y, width: width, height: height)
    }

    
    static func IoU(_ a: CGRect, _ b: CGRect) -> Float {
        let intersection = a.intersection(b)
        let union = a.union(b)
        return Float((intersection.width * intersection.height) / (union.width * union.height))
    }
    
    static func nonMmaxinumSuppression(_ objects : [VNRecognizedObjectObservation]) -> [VNRecognizedObjectObservation] {
        let nms_threshold: Float = 0.3 // IoU値の閾値
        var results: [VNRecognizedObjectObservation] = []
        var keep = [Bool] (repeating: true, count: objects.count)
        
        let orderedObjects = objects.sorted {$0.confidence > $1.confidence}
        
        for i in 0..<orderedObjects.count {
            if keep[i] {
                results.append(orderedObjects[i])
                
                let bbox1 = orderedObjects[i].boundingBox
                for j in (i+1)..<orderedObjects.count {
                    if keep[j] {
                        let bbox2 = orderedObjects[j].boundingBox
                        if IoU(bbox1, bbox2) > nms_threshold {
                            keep[j] = false
                        }
                    }
                }
            }
        }
        return results
    }
    
    
    func drawRectangleOnImage(image: UIImage, rectangle: CGRect, color: UIColor, text: String, textPoint: CGPoint) -> UIImage? {
        // 描画コンテキストの開始
        UIGraphicsBeginImageContextWithOptions(image.size, false, 0)

        // 元の画像をコンテキストに描画する
        image.draw(at: .zero)

        // 描画設定
        let context = UIGraphicsGetCurrentContext()
        context?.setStrokeColor(color.cgColor)
        context?.setLineWidth(2) // 枠線の幅
        context?.setFillColor(color.withAlphaComponent(0.5).cgColor) // 四角形の塗りつぶし色と透明度

        // 四角形のパスを追加する
        context?.addRect(rectangle)
        context?.drawPath(using: .fillStroke) // 塗りつぶしと枠線の描画

        // テキストの描画設定
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 90),
            .foregroundColor: UIColor.black
        ]

        // テキストの描画    context?.saveGState()  // 現在の描画状態を保存
        context?.translateBy(x: textPoint.x, y: textPoint.y)  // 回転の中心をテキスト位置に移動
        
        //context?.rotate(by: CGFloat(-90 * Double.pi / 180))  // -90度回転
        let attributedText = NSAttributedString(string: text, attributes: attributes)
        attributedText.draw(at: CGPoint(x: 0, y: 0))  // 回転後の座標で描画
         
        context?.restoreGState()  // 描画状態を復元
        
        // 新しい画像をコンテキストから取得する
        let newImage = UIGraphicsGetImageFromCurrentImageContext()

        // 描画コンテキストの終了
        UIGraphicsEndImageContext()
        
        //print(newImage?.getWidth(),newImage?.getHeight(),image.getWidth(),image.getHeight())

        return newImage
    }
    
    
}
