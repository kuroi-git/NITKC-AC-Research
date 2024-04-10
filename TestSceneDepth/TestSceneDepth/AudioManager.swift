//
//  AudioManager.swift
//  SoundContinuous
//
//  Created by Shirai on 2023/11/27.
//

import AVFoundation
import UIKit

// アラーム管理

class AudioManager: ObservableObject {
    
    private let audioPlayer:AVAudioPlayer
    
    // ファイル指定
    init(fileName: String) {
        audioPlayer = try!  AVAudioPlayer(data: NSDataAsset(name: fileName)!.data)
    }
    init() {
        audioPlayer = try!  AVAudioPlayer(data: NSDataAsset(name: "Alert")!.data)
    }
    // 再生
    func playSound(){
//        print("再生します")
        audioPlayer.stop()
        audioPlayer.currentTime = 0.0
        audioPlayer.play()
    }
    // 左右のバランス
    func changePan(pan:Float){
        audioPlayer.pan = pan
    }
    // 音量
    func changeVol(vol:Float){
        audioPlayer.volume = vol
    }
    // アラームの情報を返す
    func getInfo() -> String{
        if audioPlayer.pan > 0{
            return String(format: "方向: 右 %.3f , 音量: %.3f", abs(audioPlayer.pan), audioPlayer.volume)
        } else if audioPlayer.pan < 0{
            return String(format: "方向: 左 %.3f , 音量: %.3f", abs(audioPlayer.pan), audioPlayer.volume)
        } else {
            return String(format: "方向: 正面, 音量: %.3f", audioPlayer.volume)
        }
    }
    
    // 再生されているか判断、音の被りや再生し直しの対処
    func isPlaying() -> Bool {
        return audioPlayer.isPlaying
    }
}
