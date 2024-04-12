# NITKC-AC-Research
## 注意
容量の関係でOpenCVのフレームワークと物体検出用の学習済みモデルは削除している。  
それぞれ以下のパスに置くと動作すると思われる。。。  
    OpenCVのフレームワーク：`TestSceneDepth\common\opencv2.framework`  
    学習済モデル：`TestSceneDepth\TestSceneDepth\yolov8s.mlmodel`  
## 内容
駅ホームでの視覚障害者の転落防止のためのアプリである。LiDARと呼ばれる距離計測機器と物体検出を用いてアルゴリズムを考案し、開発を行った。  
### 転落状況
- ホーム端に気付かない
- 何らかの原因で方向感覚を失った
- 列車の位置を勘違いして踏み外した
### アプリの全体像
![特研発表-全体像 drawio](https://github.com/kuroi-git/NITKC-AC-Research/assets/149265808/8d5a51ec-5f99-4d5d-a150-ee2e2924f97d)
### 物体検出
YOLOによる物体検出
### 段差検出
LiDARによる距離情報から検出。段差部分は急激な距離の差が生まれるため、そこで判断
### 危険通知
累積危険値というものを導入し、誤判断の影響を少なくする。
![累積危険度 drawio](https://github.com/kuroi-git/NITKC-AC-Research/assets/149265808/17065e7e-fa7c-400e-b0f3-eb3d6ca96665)
## アルゴリズム
ここでは考案した種類だけ紹介する。詳しい内容は論文などを参照されたい。
- ホーム端の検出
- 障害物の検出
- 電車の位置の判断
