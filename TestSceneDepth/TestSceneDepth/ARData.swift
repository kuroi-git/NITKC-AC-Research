//
//  ARData.swift
//  TestSceneDepth
//
//  Created by Shirai on 2023/06/20.
//

import Foundation
import SwiftUI
import ARKit
import opencv2

// final: 継承されるのを禁止できるらしい、なんで付けたか知らない
final class ARData{
    var depthMap: CVPixelBuffer?                // 深度データが格納される
    var confidenceMap: CVPixelBuffer?           // 信頼度データが格納される
    var capturedImage: CVPixelBuffer?           // RGB画像が格納される
    var smoothedDepthMap: CVPixelBuffer?        // 平均化？された深度データ
    var smoothedConfidenceMap: CVPixelBuffer?   // 平均化された信頼度データ
    static var count = 0                        // 実行回数の変数
    var shottime = Date()                       // 処理速度確認のための変数？
    static var time = CFAbsoluteTimeGetCurrent()    // こっちも多分そう
    


    // ARSessionのsessionでdepthMapなどは取得されている
    // エッジ画像を作って送る関数かな？
    // 追記：こっちは距離情報から直接、段差を見つけるやつ、下のgetEdgeMapUIImageは深度画像からCanny関数で段差を見つけるやつ
    // opacityは有効距離
    public func getRawDepth(threshold:Float32, opacity:Double = 5.0) -> UIImage? {
        let start = Date()  // 処理速度の検証
        
        // depthMap（距離情報）から
        guard var pixelBuffer = depthMap else { return nil }        // データ置き換え
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)        // アクセスするんでロックします、みたいなやつ
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }    // 処理終わったらアンロックするよっていうのを先に宣言しとく
        
        let width = pixelBuffer.width
        let height = pixelBuffer.height
        // この辺はよくわかってない、ChatGPT最高
        // print(width, height, baseAddress, bytesPerRow, buffer)
        // で確認すると分かるかも
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)          // 
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)          // 列ごとのバイト数を取得？
        let buffer = baseAddress?.assumingMemoryBound(to: Float32.self)     // 下のコードを見る限り、ここに距離情報が入っている？
        
        var pixelData = [UInt8](repeating: 0, count: width * height * 4)    // 距離情報のw×hのサイズの配列を作成？おそらく一次元、確か、1ピクセルだけどRGBAだから4つ分の要素があるんじゃなかったかなあああ
        // pixelDataは作成する画像などの情報を代入するための配列


        // 各ピクセルを調査 横⇨縦
        for y in 0..<height {           // y
            for x in 0..<width {        // x
                let offset = (y * width + x) * 4                    // 各ピクセルの最初の部分を取得
                if(x==0 || y==0 || x==width-1 || y==height-1){      // 画像上の上下左右の端だったら、適当に値を入れてあとは省略、
                    // RGBAごとに値を入れてる、ただし、BGRAか何かになってるはずだから注意
                    pixelData[offset] = 100
                    pixelData[offset+1] = 150
                    pixelData[offset+2] = 200
                    pixelData[offset+3] = UInt8(255)    // A(透明度)
                    continue
                }

                var color:UInt8 = 0     // 黒にする
                
                let depthValue = buffer?[y * bytesPerRow / 4 + x] ?? 0.0    // 距離情報を代入、もしエラーだったら0を代入
                if depthValue > Float32(opacity) {                          // 有効距離より遠い距離だった場合、黒にする
                    pixelData[offset] = color
                    pixelData[offset+1] = color
                    pixelData[offset+2] = color
                    pixelData[offset+3] = UInt8(255)
                    continue
                }
                
                // 有効距離内だった場合の処理
                // 対象ピクセルの上下左右の値を取得する
                let depthUp      = buffer?[(y-1) * bytesPerRow / 4 + (x+0)] ?? 0.0
                let depthDown    = buffer?[(y+1) * bytesPerRow / 4 + (x+0)] ?? 0.0
                let depthRight   = buffer?[(y+0) * bytesPerRow / 4 + (x+1)] ?? 0.0
                let depthLeft    = buffer?[(y+0) * bytesPerRow / 4 + (x-1)] ?? 0.0
                
                
                // 距離の差が閾値より離れていたら色を白とする、この処理があるということは段差を抽出した画像（エッジ画像）を作成している気がする
                // 色々テストしてたから関数名とかごちゃごちゃです、すみません、、、
                if(abs(depthValue-depthUp)>threshold || abs(depthValue-depthDown)>threshold || abs(depthValue-depthRight)>threshold || abs(depthValue-depthLeft)>threshold){
                    color = 255
                }
                
                // if文から外すことで、閾値以上なら白、閾値以下なら黒と出来る
                pixelData[offset] = color
                pixelData[offset+1] = color
                pixelData[offset+2] = color
                pixelData[offset+3] = UInt8(255)
            }
        }
        
        // このへんは画像にするおまじない、ChatGPTに聞いてください
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let data = NSData(bytes: pixelData, length: pixelData.count)
        
        let providerRef = CGDataProvider(data: data)
        
        let cgImage = CGImage(width: width,
                              height: height,
                              bitsPerComponent: 8,
                              bitsPerPixel: 32,
                              bytesPerRow: bytesPerRow,
                              space: colorSpace,
                              bitmapInfo: bitmapInfo,
                              provider: providerRef!,
                              decode: nil,
                              shouldInterpolate: true,
                              intent: CGColorRenderingIntent.defaultIntent)
        ARData.count += 1   // これは処理のカウント
        let elapsed = Date().timeIntervalSince(start)   // 処理速度
        //print(elapsed)
        return UIImage(cgImage: cgImage!)
        
        
        
    }
    
    // 深度画像の作成を行ったやつ、夏休みまではこっちの手法を使ってた、詳しくはFSS2023の資料を見てください
    // showErrorは有効距離以上のピクセルの色を変える変数
    public func getDepthMapUIImage(maxDistance: Float, showError: Bool, canCapture: Bool=false, isSmoothed: Bool=false) -> UIImage? {
        guard var pixelBuffer = depthMap else { return nil }
        if isSmoothed==true{    // 平均化された方を使う設定ならこっち
            pixelBuffer = smoothedDepthMap!
        }
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        
        let width = pixelBuffer.width
        let height = pixelBuffer.height
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let buffer = baseAddress?.assumingMemoryBound(to: Float32.self)
        
        var pixelData = [UInt8](repeating: 0, count: width * height * 4)
        
        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * 4
                let depthValue = buffer?[y * bytesPerRow / 4 + x] ?? 0.0
                
                // 正規化してる、正規化の値をmaxDistanceで決めてる、固定したほうが都合がいい
                // 深度画像だから、グレースケールにしてる、RGB画像（カラフル深度画像）でも出せるけど、エッジ検出が大変だからやめてる
                // 5mを256で分けることになる
                // 余談だけど深度画像にするとmaxDistanceの距離付近が急激に白くなって正しいのかわからん、角度の問題で後半急激になるのは分かるけど、にしてもって感じ
                let normalizedColor = depthValue/maxDistance * 255
                
                // RGB
                var red: UInt8
                var green: UInt8
                var blue: UInt8
                
                // 正規化した値を代入、255以上（maxDistance以上）なら白or赤
                if showError {      // showErrorがtrueなら赤色に
                    red = normalizedColor<=255 ? UInt8(normalizedColor) : 255
                    green = normalizedColor<=255 ? UInt8(normalizedColor) : 0
                    blue = normalizedColor<=255 ? UInt8(normalizedColor) :0
                } else {    // falseなら白のまま
                    red = normalizedColor<=255 ? UInt8(normalizedColor) : 255
                    green = normalizedColor<=255 ? UInt8(normalizedColor) : 255
                    blue = normalizedColor<=255 ? UInt8(normalizedColor) : 255
                }
                
                // pixelData（画像変換用の配列）に上記の処理で決まった値を入れる
                pixelData[offset] = red
                pixelData[offset+1] = green
                pixelData[offset+2] = blue
                pixelData[offset+3] = 255
            }
        }
        //print(time2.timeIntervalSince(time1))
        
        
        /*
        let side = 1
        for i in -side..<side+1{
            for j in -side..<side+1 {
                let y = Int(height/2)+i
                let x = Int(width/2)+j
                let offset = (y * width + x) * 4
                let depthValue = buffer?[y * bytesPerRow / 4 + x] ?? 0.0
                pixelData[offset] = 0
                pixelData[offset+1] = 255
                pixelData[offset+2] = 0
                pixelData[offset+3] = 255
            }
        }
        */
        
        // おまじない
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let data = NSData(bytes: pixelData, length: pixelData.count)
        
        let providerRef = CGDataProvider(data: data)
        
        let cgImage = CGImage(width: width,
                              height: height,
                              bitsPerComponent: 8,
                              bitsPerPixel: 32,
                              bytesPerRow: bytesPerRow,
                              space: colorSpace,
                              bitmapInfo: bitmapInfo,
                              provider: providerRef!,
                              decode: nil,
                              shouldInterpolate: true,
                              intent: CGColorRenderingIntent.defaultIntent)
        ARData.count += 1
        // 保存用の処理、2回に1回保存する
        if ARData.count%2 == 0 && canCapture == true {
            UIImageWriteToSavedPhotosAlbum(UIImage(cgImage: cgImage!), self, nil, nil)
            UIImageWriteToSavedPhotosAlbum((capturedImage?.convertToUIImage())!, self, nil, nil)
//            print("debug: \(String(format: "%.5f", Date().timeIntervalSince(shottime)))")
//            shottime = Date()
        }
        
        return UIImage(cgImage: cgImage!)
        
        
    }
    
    // 信頼度画像を生成、取得する
    public func getConfMapUIImage() -> UIImage? {
        guard var pixelBuffer = confidenceMap else { return nil }
        /*
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        
        let width = pixelBuffer.width
        let height = pixelBuffer.height
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let buffer = baseAddress?.assumingMemoryBound(to: Float32.self)
        
        var pixelData = [UInt8](repeating: 0, count: width * height * 4)
        
        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * 4
                let confValue = buffer?[y * bytesPerRow / 4 + x] ?? 0.0
                
                pixelData[offset] = UInt8(confValue*255/3)
                pixelData[offset+1] = UInt8(confValue*255/3)
                pixelData[offset+2] = UInt8(confValue*255/3)
                pixelData[offset+3] = 255
            }
        }
        
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let data = NSData(bytes: pixelData, length: pixelData.count)
        
        let providerRef = CGDataProvider(data: data)
        
        let cgImage = CGImage(width: width,
                              height: height,
                              bitsPerComponent: 8,
                              bitsPerPixel: 32,
                              bytesPerRow: bytesPerRow,
                              space: colorSpace,
                              bitmapInfo: bitmapInfo,
                              provider: providerRef!,
                              decode: nil,
                              shouldInterpolate: true,
                              intent: CGColorRenderingIntent.defaultIntent)
        
        return UIImage(cgImage: cgImage!)
        */
        
        // どっかのサイトを使ってる気がする
        // https://tech.aptpod.co.jp/entry/2020/12/22/100000
        // なんでこれ使ったかは忘れた、上のでもうまくいきそうだけど
        let lockFlags: CVPixelBufferLockFlags = CVPixelBufferLockFlags(rawValue: 0)
        CVPixelBufferLockBaseAddress(pixelBuffer, lockFlags)
        guard let rawBuffer = CVPixelBufferGetBaseAddress(pixelBuffer) else { return nil }
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let len = bytesPerRow*height
        let stride = MemoryLayout<UInt8>.stride
        var i = 0
        while i < len {
            let data = rawBuffer.load(fromByteOffset: i, as: UInt8.self)
            let v = UInt8(ceil(Float(data) / Float(ARConfidenceLevel.high.rawValue) * 255))
            rawBuffer.storeBytes(of: v, toByteOffset: i, as: UInt8.self)
            i += stride
        }
        CVPixelBufferUnlockBaseAddress(pixelBuffer, lockFlags)
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let cgImage = CIContext().createCGImage(ciImage, from: ciImage.extent)
        guard let image = cgImage else { return nil }
        return UIImage(cgImage: image)
        
    }
    
    
    
    
    // エッジ画像作成（深度画像⇨OpenCVの使用⇨エッジ画像ってタイプ）
    // 深度画像を使わないなら要らないと思う、上のgetRaw
    public func getEdgeMapUIImage(maxDistance: Float, showError: Bool, canCapture: Bool=false, isSmoothed: Bool=false, th1:Int = 40, th2:Int = 120, opacity:Double = 5.0) -> UIImage? {
        
//        let time0 = Date()
        
        let r2g = OpencvFuncs()     // openCVの関数がまとめられたクラス
        
        guard var pixelBuffer = depthMap else { return nil }
        if isSmoothed==true{
            pixelBuffer = smoothedDepthMap!
        }
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        
        let width = pixelBuffer.width
        let height = pixelBuffer.height
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let buffer = baseAddress?.assumingMemoryBound(to: Float32.self)
        
        var pixelData = [UInt8](repeating: 0, count: width * height * 4)
        
        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * 4
                let depthValue = buffer?[y * bytesPerRow / 4 + x] ?? 0.0
                
                let normalizedColor = fabs(depthValue/maxDistance * 255)
                
                var red: UInt8
                var green: UInt8
                var blue: UInt8
                
                if showError {
                    red = normalizedColor<=255 ? UInt8(normalizedColor) : 255
                    green = normalizedColor<=255 ? UInt8(normalizedColor) : 0
                    blue = normalizedColor<=255 ? UInt8(normalizedColor) :0
                } else {
                    red = normalizedColor<=255 ? UInt8(normalizedColor) : 255
                    green = normalizedColor<=255 ? UInt8(normalizedColor) : 255
                    blue = normalizedColor<=255 ? UInt8(normalizedColor) : 255
                }
                
                pixelData[offset] = red
                pixelData[offset+1] = green
                pixelData[offset+2] = blue
                pixelData[offset+3] = 255
            }
        }
        
        
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let data = NSData(bytes: pixelData, length: pixelData.count)
        
        let providerRef = CGDataProvider(data: data)
        
        let cgImage = CGImage(width: width,
                              height: height,
                              bitsPerComponent: 8,
                              bitsPerPixel: 32,
                              bytesPerRow: bytesPerRow,
                              space: colorSpace,
                              bitmapInfo: bitmapInfo,
                              provider: providerRef!,
                              decode: nil,
                              shouldInterpolate: true,
                              intent: CGColorRenderingIntent.defaultIntent)
         
        // ここまでgetDepthMapUIImageと同じ
        
        
        
        ARData.count += 1
        
        if ARData.count%2 == 0 && canCapture == true {
            UIImageWriteToSavedPhotosAlbum(UIImage(cgImage: cgImage!), self, nil, nil)
            UIImageWriteToSavedPhotosAlbum((capturedImage?.convertToUIImage())!, self, nil, nil)
            print("debug: \(String(format: "%.5f", Date().timeIntervalSince(shottime)))")
            shottime = Date()
        }
        
//        let time3 = Date()
        
        let edgeImg = r2g.rgb2threshold(img: UIImage(cgImage: cgImage!), th1: th1,th2:th2)      // 作成した深度画像とCanny関数を使ってエッジを見つける
        
        return edgeImg
    }
    
    public func getLineMapUIImage(maxDistance: Float, showError: Bool, canCapture: Bool=false, isSmoothed: Bool=false, th1:Int = 40, th2:Int = 120, line_th:Int = 40, length:Int = 25, gap:Int = 10, showDistance:Bool) -> UIImage? {
//        let time0 = Date()
        let r2g = OpencvFuncs()
        /*
        guard var pixelBuffer = depthMap else { return nil }
        if isSmoothed==true{
            pixelBuffer = smoothedDepthMap!
        }
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        
        let width = pixelBuffer.width
        let height = pixelBuffer.height
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let buffer = baseAddress?.assumingMemoryBound(to: Float32.self)
        
        var pixelData = [UInt8](repeating: 0, count: width * height * 4)
        
//        let time1 = Date()
        
        /*
         let normalized_pixelData = pixelData.map { element -> UInt8 in
         if Float(element) / maxDistance * 255 <= 255 {
         return UInt8(Float(element) / maxDistance * 255)
         } else {
         return 255
         }
         }
         */
        
        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * 4
                let depthValue = buffer?[y * bytesPerRow / 4 + x] ?? 0.0
                
                let normalizedColor = fabs(depthValue/maxDistance * 255)
                
                var red: UInt8
                var green: UInt8
                var blue: UInt8
                
                
                
                if showError {
                    red = normalizedColor<=255 ? UInt8(normalizedColor) : 255
                    green = normalizedColor<=255 ? UInt8(normalizedColor) : 0
                    blue = normalizedColor<=255 ? UInt8(normalizedColor) :0
                } else {
                    red = normalizedColor<=255 ? UInt8(normalizedColor) : 255
                    green = normalizedColor<=255 ? UInt8(normalizedColor) : 255
                    blue = normalizedColor<=255 ? UInt8(normalizedColor) : 255
                }
                
                pixelData[offset] = red
                pixelData[offset+1] = green
                pixelData[offset+2] = blue
                pixelData[offset+3] = 255
            }
        }
//        let time2 = Date()
        
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let data = NSData(bytes: pixelData, length: pixelData.count)
        
        let providerRef = CGDataProvider(data: data)
        
        let cgImage = CGImage(width: width,
                              height: height,
                              bitsPerComponent: 8,
                              bitsPerPixel: 32,
                              bytesPerRow: bytesPerRow,
                              space: colorSpace,
                              bitmapInfo: bitmapInfo,
                              provider: providerRef!,
                              decode: nil,
                              shouldInterpolate: true,
                              intent: CGColorRenderingIntent.defaultIntent)
        */
        var color = getCapturedUIImage()    // 多分これ要らない


        guard var pixelBuffer = depthMap else { return nil }
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        
        let width = pixelBuffer.width
        let height = pixelBuffer.height
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let buffer = baseAddress?.assumingMemoryBound(to: Float32.self)
        
        var pixelData = [UInt8](repeating: 0, count: width * height * 4)
        
        // bufferに距離情報、pixelDataは空

        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * 4
                // 四隅を0にする
                if(x==0 || y==0 || x==width-1 || y==height-1){
                    pixelData[offset] = 0
                    pixelData[offset+1] = 0
                    pixelData[offset+2] = 0
                    pixelData[offset+3] = UInt8(255)
                    continue
                }
                var color:UInt8 = 0
                //10m以上を無視
                // なんでこれ10mにしてるんだろ、多分引数追加するのだるくて手打ちにしてる、有効距離として使う引数を追加して置き換えるべき
                let depthValue = buffer?[y * bytesPerRow / 4 + x] ?? 0.0
                if depthValue > Float32(10.0) {
                    pixelData[offset] = color
                    pixelData[offset+1] = color
                    pixelData[offset+2] = color
                    pixelData[offset+3] = UInt8(255)
                    continue
                }
                
                let depthUp      = buffer?[(y-1) * bytesPerRow / 4 + (x+0)] ?? 0.0
                let depthDown    = buffer?[(y+1) * bytesPerRow / 4 + (x+0)] ?? 0.0
                let depthRight   = buffer?[(y+0) * bytesPerRow / 4 + (x+1)] ?? 0.0
                let depthLeft    = buffer?[(y+0) * bytesPerRow / 4 + (x-1)] ?? 0.0
                
                // maxDistanceは段差距離
                if(abs(depthValue-depthUp)>maxDistance || abs(depthValue-depthDown)>maxDistance || abs(depthValue-depthRight)>maxDistance || abs(depthValue-depthLeft)>maxDistance){
                    color = 255
                }
                
                
                pixelData[offset] = color
                pixelData[offset+1] = color
                pixelData[offset+2] = color
                pixelData[offset+3] = UInt8(255)
            }
        }

        // おまじない、エッジ画像を作成する
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let data = NSData(bytes: pixelData, length: pixelData.count)
        
        let providerRef = CGDataProvider(data: data)
        
        let cgImage = CGImage(width: width,
                              height: height,
                              bitsPerComponent: 8,
                              bitsPerPixel: 32,
                              bytesPerRow: bytesPerRow,
                              space: colorSpace,
                              bitmapInfo: bitmapInfo,
                              provider: providerRef!,
                              decode: nil,
                              shouldInterpolate: true,
                              intent: CGColorRenderingIntent.defaultIntent)
        ARData.count += 1
        if ARData.count%2 == 0 && canCapture == true {
            UIImageWriteToSavedPhotosAlbum(UIImage(cgImage: cgImage!), self, nil, nil)
            UIImageWriteToSavedPhotosAlbum((capturedImage?.convertToUIImage())!, self, nil, nil)
            print("debug: \(String(format: "%.5f", Date().timeIntervalSince(shottime)))")
            shottime = Date()
        }
        
        // エッジ画像に対して線分検出を行う
        let lineImg = r2g.rgb2line(maxDistance: maxDistance, img: UIImage(cgImage: cgImage!), th1: th1, th2: th2, line_th: line_th, length: length, gap: gap,showDistance:showDistance, showError:showError)
        
        return lineImg
    }
    
    // RGB画像を取得する関数
    public func getCapturedUIImage() -> UIImage? {
//        print(String(format:"all:%0.5f",CFAbsoluteTimeGetCurrent()-ARData.time), terminator: " ")
        DebugTest.debugPrint(String(format:"%0.5f",CFAbsoluteTimeGetCurrent()-ARData.time), nl:false)
        ARData.time = CFAbsoluteTimeGetCurrent()
        let start = CFAbsoluteTimeGetCurrent()
//        print(String(format:"col: %0.5f",CFAbsoluteTimeGetCurrent()-start), terminator: " ")
        DebugTest.debugPrint(String(format:"%0.5f",CFAbsoluteTimeGetCurrent()-start), nl:false)

        // 本来の機能はここだけ、上はデバッグとか、速度検証で使ったやつが残ってる？
        let image = capturedImage?.convertToUIImage()
        return image
    }
    
    // 遊び関数、RGB画像に対するエッジ画像作成、組み合わせが出来ないか検証するために実装
    public func getCapturedEdgeUIImage() -> UIImage? {
        let r2g = OpencvFuncs()
        let edgeImg = r2g.rgb2threshold(img: (capturedImage?.convertToUIImage())!, th1: 40,th2:120)
        return edgeImg
//        let image = capturedImage?.convertToUIImage()
    }
    
    // CSVファイルとして距離情報を保存する
    public func saveRawDepthData(isSmoothed: Bool=false) {
        
        let now = Date()

        // DateFormatter のインスタンスを作成
        let formatter = DateFormatter()

        // フォーマットを設定（例: "yyyy-MM-dd HH:mm:ss"）
        formatter.dateFormat = "yyyy-MM-dd HH：mm：ss：SSS"

        // 日時を String に変換
        let dateString = formatter.string(from: now)
        
        var pixelBuffer = depthMap
        if isSmoothed==true{
            pixelBuffer = smoothedDepthMap!
        }
        CVPixelBufferLockBaseAddress(pixelBuffer!, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer!, .readOnly) }
        
        let width = pixelBuffer!.width
        let height = pixelBuffer!.height
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer!)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer!)
        let buffer = baseAddress?.assumingMemoryBound(to: Float32.self)
        
        var pixelData = [UInt8](repeating: 0, count: width * height * 4)
        
        let m = height  // 行数
        let n = width  // 列数
        var array = Array(repeating: Array(repeating: Float32(0.0), count: n), count: m)

        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * 4
                let depthValue = buffer?[y * bytesPerRow / 4 + x] ?? 0.0
                array[y][x]=depthValue
            }
        }
        //print(String(width) + "," + String(height))
        // CSV形式の文字列を生成する
        var csvString = ""
        for row in array {
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
    
    // 二次元配列の距離情報を返す
    // 回転に注意！(端付近の距離情報を確認して、実際の位置と配列の座標の関係を検証すべき)
    public func getDepthData(isSmoothed: Bool=false) ->  [[Float32]] {
        // 検証用
        let start = CFAbsoluteTimeGetCurrent()
        
        var pixelBuffer = depthMap
        if isSmoothed==true{
            pixelBuffer = smoothedDepthMap!
        }
        CVPixelBufferLockBaseAddress(pixelBuffer!, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer!, .readOnly) }
        
        let width = pixelBuffer!.width
        let height = pixelBuffer!.height
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer!)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer!)
        let buffer = baseAddress?.assumingMemoryBound(to: Float32.self)
        
        var pixelData = [UInt8](repeating: 0, count: width * height * 4)
        
        let m = height  // 行数
        let n = width  // 列数
        var array = Array(repeating: Array(repeating: Float32(0.0), count: n), count: m)

        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * 4
                let depthValue = buffer?[y * bytesPerRow / 4 + x] ?? 0.0
                array[y][x]=depthValue
            }
        }
//        print(String(format:"Depth:%0.5f",CFAbsoluteTimeGetCurrent() - start), terminator: " ")
        DebugTest.debugPrint(String(format:"%0.5f",CFAbsoluteTimeGetCurrent() - start), nl:false)
        return array
    }

    // 検出した線分（段差部分）の2点の座標をすべて返す（二次元配列で返す）
    public func getLinePoints(maxDistance: Float, isSmoothed: Bool=false, th1:Int = 40, th2:Int = 120, line_th:Int = 40, length:Int = 25, gap:Int = 10, opacity: Double = 5.0) -> [[Point]] {
        let start = CFAbsoluteTimeGetCurrent()

        let r2g = OpencvFuncs()
        
        /*
        var pixelBuffer = depthMap!
        if isSmoothed==true{
            pixelBuffer = smoothedDepthMap!
        }
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        
        let width = pixelBuffer.width
        let height = pixelBuffer.height
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let buffer = baseAddress?.assumingMemoryBound(to: Float32.self)
        
        var pixelData = [UInt8](repeating: 0, count: width * height * 4)
        
        
        /*
         let normalized_pixelData = pixelData.map { element -> UInt8 in
         if Float(element) / maxDistance * 255 <= 255 {
         return UInt8(Float(element) / maxDistance * 255)
         } else {
         return 255
         }
         }
         */
        
        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * 4
                let depthValue = buffer?[y * bytesPerRow / 4 + x] ?? 0.0
                
                let normalizedColor = fabs(depthValue/maxDistance * 255)
                
                var red: UInt8
                var green: UInt8
                var blue: UInt8

                red = normalizedColor<=255 ? UInt8(normalizedColor) : 255
                green = normalizedColor<=255 ? UInt8(normalizedColor) : 255
                blue = normalizedColor<=255 ? UInt8(normalizedColor) : 255
                
                pixelData[offset] = red
                pixelData[offset+1] = green
                pixelData[offset+2] = blue
                pixelData[offset+3] = 255
            }
        }
        
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let data = NSData(bytes: pixelData, length: pixelData.count)
        
        let providerRef = CGDataProvider(data: data)
        
        let cgImage = CGImage(width: width,
                              height: height,
                              bitsPerComponent: 8,
                              bitsPerPixel: 32,
                              bytesPerRow: bytesPerRow,
                              space: colorSpace,
                              bitmapInfo: bitmapInfo,
                              provider: providerRef!,
                              decode: nil,
                              shouldInterpolate: true,
                              intent: CGColorRenderingIntent.defaultIntent)
        */
        
        var pixelBuffer = depthMap!
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        
        let width = pixelBuffer.width
        let height = pixelBuffer.height
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let buffer = baseAddress?.assumingMemoryBound(to: Float32.self)
        
        var pixelData = [UInt8](repeating: 0, count: width * height * 4)
        
        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * 4
                if(x==0 || y==0 || x==width-1 || y==height-1){
                    pixelData[offset] = 0
                    pixelData[offset+1] = 0
                    pixelData[offset+2] = 0
                    pixelData[offset+3] = UInt8(255)
                    continue
                }
                var color:UInt8 = 0
                
                let depthValue = buffer?[y * bytesPerRow / 4 + x] ?? 0.0
                if depthValue > Float32(10.0) {
                    pixelData[offset] = color
                    pixelData[offset+1] = color
                    pixelData[offset+2] = color
                    pixelData[offset+3] = UInt8(255)
                    continue
                }
                
                let depthUp      = buffer?[(y-1) * bytesPerRow / 4 + (x+0)] ?? 0.0
                let depthDown    = buffer?[(y+1) * bytesPerRow / 4 + (x+0)] ?? 0.0
                let depthRight   = buffer?[(y+0) * bytesPerRow / 4 + (x+1)] ?? 0.0
                let depthLeft    = buffer?[(y+0) * bytesPerRow / 4 + (x-1)] ?? 0.0
                
                
                if((abs(depthValue-depthUp)>maxDistance || abs(depthValue-depthDown)>maxDistance || abs(depthValue-depthRight)>maxDistance || abs(depthValue-depthLeft)>maxDistance) && depthValue<Float(opacity)) {
                    color = 255
                }
                
                
                pixelData[offset] = color
                pixelData[offset+1] = color
                pixelData[offset+2] = color
                pixelData[offset+3] = UInt8(255)
            }
        }
        
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let data = NSData(bytes: pixelData, length: pixelData.count)
        
        let providerRef = CGDataProvider(data: data)
        
        let cgImage = CGImage(width: width,
                              height: height,
                              bitsPerComponent: 8,
                              bitsPerPixel: 32,
                              bytesPerRow: bytesPerRow,
                              space: colorSpace,
                              bitmapInfo: bitmapInfo,
                              provider: providerRef!,
                              decode: nil,
                              shouldInterpolate: true,
                              intent: CGColorRenderingIntent.defaultIntent)

        // ここまでで、エッジ画像を作成している
        // この下でポイントを取得している、変数名は変えるの面倒で変えてないだけだと思う
        let edgeImg = r2g.getLinePoints(maxDistance: maxDistance, img: UIImage(cgImage: cgImage!),line_th: line_th, length: length, gap: gap)
//        print(String(format:"Line%0.5f",CFAbsoluteTimeGetCurrent() - start), terminator: " ")
        DebugTest.debugPrint(String(format:"%0.5f",CFAbsoluteTimeGetCurrent() - start), nl: false)
        return edgeImg
    }
    
    // 多分、カラー画像に対して、検出した線分の座標を基に線分を表示させている
    public func getColorLineUIImage(maxDistance: Float,line_th:Int = 40, length:Int = 25, gap:Int = 10, opacity:Double = 5.0) -> UIImage? {
        let ocv2 = OpencvFuncs()
        var color = getCapturedUIImage()
        var linePoints = getLinePoints(maxDistance: maxDistance, line_th: line_th, length: length, gap: gap, opacity: opacity)
        let distance = getDepthData()

                
        return ocv2.drawLines(lineList: linePoints, image: color!,distance:distance)

    }
    
}
