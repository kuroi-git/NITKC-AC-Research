//
//  OverlapImageView.swift
//  TestSceneDepth
//
//  Created by Shirai on 2023/08/08.
//

import SwiftUI

// 重ねた画像を表示するためのビュー

struct OverlapImageView: View {
    var myImage1: UIImage
    var myImage2: UIImage
    var opacity: Double
    
    var body: some View {
        
        Button(action:{UIImageWriteToSavedPhotosAlbum(myImage1, self, nil, nil);UIImageWriteToSavedPhotosAlbum(myImage2, self, nil, nil)}){Text("保存")}
        Spacer().frame(height: 50)
        // myImage1 と myImage2を重ねる
        ZStack{
            Image(uiImage: myImage1)
                .resizable()
                .rotationEffect(.degrees(90))
                .aspectRatio(contentMode: .fit) // アスペクト比を維持し、指定した幅に収まるようにします
                .frame(width: 380)
            Image(uiImage: myImage2)
                .resizable()
                .rotationEffect(.degrees(90))
                .aspectRatio(contentMode: .fit) // アスペクト比を維持し、指定した幅に収まるようにします
                .frame(width: 380)
                .opacity(opacity)
        }
    }
}
