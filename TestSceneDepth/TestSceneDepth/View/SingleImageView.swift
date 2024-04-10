//
//  SingleImageView.swift
//  TestSceneDepth
//
//  Created by Shirai on 2023/08/05.
//

import SwiftUI

// 一枚の画像を表示するためのビュー

struct SingleImageView: View {
    var myImage: UIImage
    
    var body: some View {
            Spacer().frame(height: 50)
            Image(uiImage: myImage)
                .resizable()
                .rotationEffect(.degrees(90))
                .aspectRatio(contentMode: .fit) // アスペクト比を維持し、指定した幅に収まるようにします
                .frame(width: 380)
    }
}
