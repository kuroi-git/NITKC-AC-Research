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

## 精度検証
### 検証1（全体評価）
駅のホームを往来して得たデータをランダムに抽出し、駅ホームまでの最短距離（画像上）と検出の有無を検証した。結果は以下のようになった。
![image](https://github.com/kuroi-git/NITKC-AC-Research/assets/149265808/d6e5a4f4-59cb-4075-9d9a-6d07885bf23b)
全体の精度は約81%となった。しかし、点字ブロックとホーム端の距離は、0.8m~1.0mであり、検証結果によると1.5m以内であれば、約98.5%となっており、危険な状況であれば高精度で検出して警告することができる。
![image](https://github.com/kuroi-git/NITKC-AC-Research/assets/149265808/d284c6cd-524f-48b4-82ef-ce1a99a0e8c5)

### 検証2（角度検証）
駅ホームからの最短距離を固定し、そこからの駅ホームに対する角度を変化させて、角度による精度の検証を行った。
![image](https://github.com/kuroi-git/NITKC-AC-Research/assets/149265808/55fb8289-4ce6-4dc5-8bce-f940de61eed1)
精度は以下のようになった。結果は、距離が離れ、かつ角度が開くほど精度が悪くなった。しかし、点字ブロックがある場所より遠い1.5m以内であれば約96.5%であり、こちらも危険な状況になったとき、段差を検出できると考えられる。
![image](https://github.com/kuroi-git/NITKC-AC-Research/assets/149265808/3944e3c6-eff2-412d-8412-7c80ff72726d)
