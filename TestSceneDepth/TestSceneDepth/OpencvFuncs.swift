//
//  OpencvFuncs.swift
//  TestSceneDepth
//
//  Created by Shirai on 2023/08/04.
//

// OpenCVを使った関数を定義している。
// OpenCVを導入する必要あり、ネットの記事は小難しいのが書いてあるけど、自分はOpenCVのファイル移して設定ちょっと変えただけで出来た（どっかの記事に書いてあるはず、もしくはChatGPT）

import Foundation
import opencv2

class OpencvFuncs:ObservableObject {

    // 受け取った線分の座標リスト（2次元配列）と距離情報を基に、引数の画像に対して、線分と距離（文字）を描写する
    public func drawLines(lineList:[[Point]],image:UIImage,distance:[[Float]]) -> UIImage {
        var img = image //image.rotateImageLeft90Degrees(image)     // とりあえず代入
        var src = Mat(uiImage: img)                                 // OpenCV
        let adj = Int32(0)                                          // 線分がズレてる時があって、それの修正のための変数？0にしてるってことは解決した？？見て確認してほしい
        //Imgproc.cvtColor(src: src, dst: src, code: ColorConversionCodes.)

        // 線分描写
        for point in lineList {
            // print(image.getHeight(),image.getWidth()) // 1440 1920
            // xは200以上　yは200未満
            // カラー画像とLiDARからの距離情報は座標の数に違いがある、つまり、サイズ比から調整する必要がある。
            // lineListは線分のリスト（point型の配列（2つの配列））
            // 変数pointは2つの座標（point型）が入っていて、point型のフィールド？変数？にxとyがある、これらが座標のx、yである。
            // pt1、pt2が線分を構成する2点、各引数にはxyの2軸が必要であるため、Point型にしている
            // xとyの式に関して
            // point[0 or 1].x or y　は距離情報の座標であり、カラー画像の座標とは最大値が違う（カラー画像が考慮されるのは、物体検出の結果などがカラー画像の座標を使うため）
            // そこで正規化して、カラー画像の座標と合わせる　⇨　point[0].x/256やpoint[1].y/196が正規化の作業、あとはimage.getWidthなどで画像の縦横の最大値をかける
            Imgproc.line(img: src, pt1: Point(x: point[0].x*Int32(image.getWidth())/256+adj, y: point[0].y*Int32(image.getHeight())/192+adj), pt2: Point(x: point[1].x*Int32(image.getWidth())/256+adj,y: point[1].y*Int32(image.getHeight())/192+adj), color: Scalar(0,200,0), thickness: 10)
            Imgproc.putText(img: src, text: String(format: "%.3f ms", distance[Int(point[0].y)][Int(point[0].x)]), org: Point(x: (point[0].x+point[1].x)/2*Int32(image.getWidth())/256+adj, y: (point[0].y+point[1].y)/2*Int32(image.getHeight())/192+adj), fontFace: .FONT_HERSHEY_COMPLEX, fontScale: 1, color: Scalar(255,200,100), thickness: 1)
        }
        return src.toUIImage()

    }
    
    // こっちはエッジ画像から線分のリストを返す関数
    // 1つの線分：2つの座標から構成　➔　これは配列で対応
    // 1つの座標：2つの座標軸から　➔　これはPoint型で対応
    // だから戻り地が[[Point]]（Point型の2次元配列）となる
    public func getLinePoints(maxDistance: Float, img: UIImage,th1: Int=50, th2:Int = 140, line_th: Int = 40, length: Int = 25, gap: Int = 10)-> [[Point]]{
//        let rect: CGRect = CGRectMake(5, 5, img.size.width-10, img.size.height-10)
//        let reimg = trimmingImage(img, trimmingArea: rect)
        // 空配列を作成
        var lineList:[[Point]] = []
        //print("aa")
//        print(img.size) //(256.0, 192.0)
        // OpenCV用に変換
        let src = Mat(uiImage: img)
        // グレースケール
        let gray = Mat()
        Imgproc.cvtColor(src: src, dst: gray, code: ColorConversionCodes.COLOR_BGRA2GRAY)
        
        // なんだっけこれ
        let notGray = Mat()
        Core.bitwise_not(src:gray,dst: notGray)
        
        // なんだっけこれ、、、
        let bw = Mat()
        //Imgproc.Canny(image: notGray, edges: bw, threshold1: Double(th1), threshold2: Double(th2))
        //Imgproc.adaptiveThreshold(src: notGray, dst: bw, maxValue: 255, adaptiveMethod: .ADAPTIVE_THRESH_MEAN_C, thresholdType: .THRESH_BINARY, blockSize: 3, C: -2)
        //let lineImg =  Mat(rows: bw.size().height, cols: bw.size().width, type: CV_8UC3, scalar: Scalar(0,0,255))
        var lines =  Mat()
        // ここで線分を見つける、引数で閾値などは取得することになっている
        Imgproc.HoughLinesP(image: gray, lines: lines, rho: Double(1), theta: Double(Double.pi/180.0), threshold: Int32(line_th), minLineLength: Double(length), maxLineGap: Double(gap))
        
        // データの入れ替えを行っている、別にしなくてもいいかも？
        for i in 0 ..< lines.rows(){
            let data = lines.get(row: i, col: 0)
            // どっちが近いか
            var closePoint = Point(x: Int32(data[0]),y: Int32(data[1]))
            var farPoint = Point(x: Int32(data[2]),y: Int32(data[3]))
            if data[0] < data[2] {
                closePoint = Point(x: Int32(data[2]),y: Int32(data[3]))
                farPoint = Point(x: Int32(data[0]),y: Int32(data[1]))
            }
            lineList.append([closePoint, farPoint])
        }
        //print(lineList.count)
//        print("\(lines.rows())")
        
        return lineList    // 192, 256
    }
    
    
    
    /*
    public func getLinePoints(img: UIImage,th1: Int=50, th2:Int = 140, line_th: Int = 40, length: Int = 25, gap: Int = 10)-> [[Point]]{
        let rect: CGRect = CGRectMake(5, 5, img.size.width-10, img.size.height-10)
        let reimg = trimmingImage(img, trimmingArea: rect)
        var lineList:[[Point]] = []
        
        print("bb")
        let src = Mat(uiImage: img)
        // グレースケール
        let gray = Mat()
        Imgproc.cvtColor(src: src, dst: gray, code: ColorConversionCodes.COLOR_BGRA2GRAY)
        
        // 白黒斑点
        let notGray = Mat()
        Core.bitwise_not(src:gray,dst: notGray)
        
        let bw = Mat()
        Imgproc.Canny(image: notGray, edges: bw, threshold1: Double(th1), threshold2: Double(th2))
        //Imgproc.adaptiveThreshold(src: notGray, dst: bw, maxValue: 255, adaptiveMethod: .ADAPTIVE_THRESH_MEAN_C, thresholdType: .THRESH_BINARY, blockSize: 3, C: -2)
        
        //let lineImg =  Mat(rows: bw.size().height, cols: bw.size().width, type: CV_8UC3, scalar: Scalar(0,0,255))
        var lines =  Mat()
        Imgproc.HoughLinesP(image: notGray, lines: lines, rho: Double(1), theta: Double(Double.pi/180.0), threshold: Int32(line_th), minLineLength: Double(length), maxLineGap: Double(gap))
        
        for i in 0 ..< lines.rows(){
            let data = lines.get(row: i, col: 0)
            // どっちが近いか
            var closePoint = Point(x: Int32(data[0]),y: Int32(data[1]))
            var farPoint = Point(x: Int32(data[2]),y: Int32(data[3]))
            if data[0] < data[2] {
                closePoint = Point(x: Int32(data[2]),y: Int32(data[3]))
                farPoint = Point(x: Int32(data[0]),y: Int32(data[1]))
            }
            lineList.append([closePoint, farPoint])
            
        }
//        print("\(lines.rows())")
        // xは200以上　yは200未満
        return lineList    // 192, 256
        
    }
     
     */
    
    
    // RGB画像を返してるだけ、なんと苦なく作った
    public func rgb2rgb(img: UIImage)-> UIImage{
        
        return img
    }
    

    // グレースケールにして返してるのかな？プログラムでは使ってない
    public func rgb2gray(img: UIImage)-> UIImage{
        let srcMat = Mat(uiImage: img)
//        print("チャンネル数：\(srcMat.channels())")
        let dstMat = Mat()
        Imgproc.cvtColor(src: srcMat, dst: dstMat, code: ColorConversionCodes.COLOR_BGRA2GRAY)
        let result = dstMat.toUIImage()
        return result
    }

    // 受け取った画像をエッジ画像にしている、コードを間違えていて、ズレていたときに作ったはず
    public func rgb2threshold(img: UIImage, th1: Int = 50, th2: Int = 140)-> UIImage{
        // グレースケールに
        let src = Mat(uiImage: img)
        let gray = Mat()
        Imgproc.cvtColor(src: src, dst: gray, code: ColorConversionCodes.COLOR_BGRA2GRAY)
        
        // 二値化画像に
        let notGray = Mat()
        Core.bitwise_not(src:gray,dst: notGray)
        
        let bw = Mat()
        Imgproc.Canny(image: notGray, edges: bw, threshold1: Double(th1), threshold2: Double(th2))
        Imgproc.dilate(src: bw, dst: bw, kernel: Mat.ones(rows: 2, cols: 2, type: CvType.CV_8UC1))
        //Imgproc.adaptiveThreshold(src: notGray, dst: bw, maxValue: 255, adaptiveMethod: .ADAPTIVE_THRESH_MEAN_C, thresholdType: .THRESH_BINARY, blockSize: 3, C: -2)
        
        return bw.toUIImage()
    }
    
    // 画像をトリミングする
    func trimmingImage(_ image: UIImage, trimmingArea: CGRect) -> UIImage {
        let imgRef = image.cgImage?.cropping(to: trimmingArea)
        let trimImage = UIImage(cgImage: imgRef!, scale: image.scale, orientation: image.imageOrientation)
        return trimImage
    }
    
    // [[Point]]
    public func rgb2line(maxDistance: Float, img: UIImage,th1: Int=50, th2:Int = 140, line_th: Int = 40, length: Int = 25, gap: Int = 10, showDistance:Bool, showError:Bool)-> UIImage{
        let rect: CGRect = CGRectMake(5, 5, img.size.width-10, img.size.height-10)
        //let reimg = trimmingImage(img, trimmingArea: rect)
        var pointList:[[Point]] = []
        
        let src = Mat(uiImage: img)
        // グレースケール
        let gray = Mat()
        Imgproc.cvtColor(src: src, dst: gray, code: ColorConversionCodes.COLOR_BGRA2GRAY)
        
        // 白黒斑点
        let notGray = Mat()
        Core.bitwise_not(src:gray,dst: notGray)
        
        var bw = Mat()
        Imgproc.Canny(image: notGray, edges: bw, threshold1: Double(th1), threshold2: Double(th2))
        //Imgproc.adaptiveThreshold(src: notGray, dst: bw, maxValue: 255, adaptiveMethod: .ADAPTIVE_THRESH_MEAN_C, thresholdType: .THRESH_BINARY, blockSize: 3, C: -2)
        
        //let lineImg =  Mat(rows: bw.size().height, cols: bw.size().width, type: CV_8UC3, scalar: Scalar(0,0,255))
        var lines =  Mat()
        Imgproc.HoughLinesP(image: bw, lines: lines, rho: Double(1), theta: Double(Double.pi/180.0), threshold: Int32(line_th), minLineLength: Double(length), maxLineGap: Double(gap))
        var lineImg =  Mat.zeros(bw.size().height, cols: bw.size().width, type: CvType.CV_8UC1)
        Imgproc.cvtColor(src: lineImg, dst: lineImg, code: ColorConversionCodes.COLOR_GRAY2RGB)
        
        
        for i in 0 ..< lines.rows(){
            let data = lines.get(row: i, col: 0)
            // どっちが近いか
            var closePoint = Point(x: Int32(data[0]),y: Int32(data[1]))
            var farPoint = Point(x: Int32(data[2]),y: Int32(data[3]))
            if data[0] < data[2] {
                closePoint = Point(x: Int32(data[2]),y: Int32(data[3]))
                farPoint = Point(x: Int32(data[0]),y: Int32(data[1]))
            }
//            print("\(i): \(Point2i(x: Int32(data[0]),y: Int32(data[1]))), \(Point2i(x: Int32(data[2]),y: Int32(data[3])))")
            
            //print(pointList[0][0])
            
            var color = Scalar(Double.random(in: 0...255),Double.random(in: 0...255),Double.random(in: 0...255))
            if showError{
                color = Scalar(255,50,50)
            }
            let textPoint = Point(x: closePoint.x, y: closePoint.y)
            
            Imgproc.line(img: lineImg, pt1: closePoint, pt2: farPoint, color: color, thickness: 2)
            // ×の描写
            Imgproc.line(img: lineImg, pt1: Point(x: closePoint.x, y: closePoint.y), pt2: Point(x: closePoint.x, y: closePoint.y+5), color: Scalar(100,100,255), thickness: 1)
            Imgproc.line(img: lineImg, pt1: Point(x: closePoint.x, y: closePoint.y), pt2: Point(x: closePoint.x, y: closePoint.y-5), color: Scalar(100,100,255), thickness: 1)
            Imgproc.line(img: lineImg, pt1: Point(x: closePoint.x, y: closePoint.y), pt2: Point(x: closePoint.x+5, y: closePoint.y), color: Scalar(100,100,255), thickness: 1)
            Imgproc.line(img: lineImg, pt1: Point(x: closePoint.x, y: closePoint.y), pt2: Point(x: closePoint.x-5, y: closePoint.y), color: Scalar(100,100,255), thickness: 1)
            
            if showDistance == true{
                let distance = calMinDistance(x: closePoint.x, y: closePoint.y, src: src, maxDistance: maxDistance)
                Imgproc.putText(img: lineImg, text: String(format: "%.3f ms", distance), org: textPoint, fontFace: .FONT_HERSHEY_COMPLEX, fontScale: 0.3, color: Scalar(255,200,100), thickness: 1)
            }
        }
//        print("\(lines.rows())")
        
        return lineImg.toUIImage()
    }
    
    // ある座標の距離とその上下左右の距離と比較して最小の距離を見つける
    func calMinDistance(x:Int32, y:Int32, src:Mat, maxDistance:Float) -> Double {
        var center: Double
        var up: Double
        var down: Double
        var left: Double
        var right: Double
        let p: Int32 = 10
        do{
            center = calDistance(x: x, y: y, src: src, maxDistance: maxDistance)
        } catch {
            center = calDistance(x: x, y: y, src: src, maxDistance: maxDistance)
        }
        do{
            up = calDistance(x: x, y: y-p, src: src, maxDistance: maxDistance)
        } catch {
            up = calDistance(x: x, y: y, src: src, maxDistance: maxDistance)
        }
        do{
            down = calDistance(x: x, y: y+p, src: src, maxDistance: maxDistance)
        } catch {
            down = calDistance(x: x, y: y, src: src, maxDistance: maxDistance)
        }
        do{
            left = calDistance(x: x-p, y: y, src: src, maxDistance: maxDistance)
        } catch {
            left = calDistance(x: x, y: y, src: src, maxDistance: maxDistance)
        }
        do{
            right = calDistance(x: x+p, y: y, src: src, maxDistance: maxDistance)
        } catch {
            right = calDistance(x: x, y: y, src: src, maxDistance: maxDistance)
        }
        
        return minWithoutZero(center:center, up: up, down: down, left: left, right: right)
    }
    
    // 一番小さいのを探してるんだけど、それが0だったらどうこうするよってやつ？
    func minWithoutZero(center:Double, up: Double, down: Double, left: Double, right: Double) -> Double {
        let minValue = min(center, up, down, left, right)
        
        if minValue != 0 {
            return minValue
        } else {
            let nonZeroValues = [center, up, down, left, right].filter { $0 != 0 }
            return nonZeroValues.min() ?? 0
        }
    }
    
    // 正規化してる、、、なんで正規化？？
    // 255というのは深度画像を生成したときに使う値（FSS2023の資料参照）なのに、距離情報から直接段差を検出する手法でも出てきてる、意味わからん
    func calDistance(x:Int32, y:Int32, src:Mat, maxDistance:Float) -> Double {
        var distance = src.get(row: y, col: x)[0]
        distance = distance * Double(maxDistance) / 255
        return distance
    }
    
    // なんだこれ、使ってない、確か検証用で使ったはず
    public func rgb2dst(img: UIImage) -> UIImage{
        let dstMat = Mat()
        //Imgproc.cvtColor(src: srcMat, dst: dstMat, code: ColorConversionCodes.COLOR_BGR2GRAY)
        let result = dstMat.toUIImage()
        return result
    }
    
    // これも使ってない、画像を見るときに使ってた
    func getDepthImage(no: Int) -> UIImage{
        if no == 0{
            return UIImage(named: "depth1")!
        } else if no == 1 {
            return UIImage(named: "depth2")!
        } else if no == 2 {
            return UIImage(named: "depth3")!
        } else if no == 3 {
            return UIImage(named: "depth4")!
        } else if no == 4 {
            return UIImage(named: "depth5")!
        } else if no == 5 {
            return UIImage(named: "depth6")!
        } else {
            return UIImage(named: "unkai")!
        }
    }
    // これも同じ
    func getColorImage(no: Int) -> UIImage{
        if no == 0{
            return UIImage(named: "color1")!
        } else if no == 1 {
            return UIImage(named: "color2")!
        } else if no == 2 {
            return UIImage(named: "color3")!
        } else if no == 3 {
            return UIImage(named: "color4")!
        } else if no == 4 {
            return UIImage(named: "color5")!
        } else if no == 5 {
            return UIImage(named: "color6")!
        } else {
            return UIImage(named: "unkai")!
        }
    }
    
    
    
    
}

