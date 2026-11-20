學號:115522088

## 完成項目

| 項目 | 函式 | 檔案 | 狀態 |
|---|---|---|---|
| Y 軸旋轉矩陣 | `Matrix4.makeRotY` | Matrix4.pde | 完成 |
| X 軸旋轉矩陣 | `Matrix4.makeRotX` | Matrix4.pde | 完成 |
| Model 矩陣 | `GameObject.localToWorld` | GameObject.pde | 完成 |
| View 矩陣 | `Camera.setPositionOrientation` | Camera.pde | 完成 |
| Projection 矩陣 | `Camera.setSize` | Camera.pde | 完成 |
| Depth buffer | `getDepth`、`GameObject.Draw` | util.pde、GameObject.pde | 完成 |
| 相機控制 | `cameraControl` | HW3.pde | 完成 |
| Backface culling | `GameObject.debugDraw` | GameObject.pde | 完成 |
| (前置)直線繪製 | `CGLine`(沿用 HW1,Bresenham) | util.pde | 完成 |
| (加分)3D Clipping | - | - | 未實作 |

繪製模型時未使用被禁止的內建函式 `translate()`、`scale()`、`rotateX/Y/Z()`,所有變換皆以自己實作的 `Matrix4` 完成;`fill()` 只用在作業允許的 GUI 面板。線框使用自己實作的 `CGLine`,沒有用內建的 `line()`,也未使用外部函式庫。

## 執行方式

1. 用 Processing 開啟 `sketch_115522088_HW3/sketch_115522088_HW3.pde`。
2. 確認 `data/cube.png`、`data/debug.png` 存在。
3. 按 Run,點左上角的方塊按鈕選擇 `.obj` 模型(例如 `cube.obj`)。
4. 點中間 Hierarchy 的項目,用右側 Inspector 的滑桿調整 position、rotation、scale。
5. 相機操作:
   - `W` / `S`:前進 / 後退
   - `A` / `D`:左移 / 右移
   - `Q` / `E`:下降 / 上升
   - 在左側渲染區內按住滑鼠拖曳:轉動視角
6. 點左上角的蟲子按鈕可以開關線框(debug 模式)。

## 各項目做法

### 1. 旋轉矩陣(Matrix4.pde)

引擎採用 4x4 矩陣、列優先陣列 `m[16]`,與列向量相乘(`M * v`)。兩個函式都先 `makeIdentity()`,再填入對應的元素。本引擎以 Y 軸朝上。

- 繞 Y 軸:`m[0]=cos a, m[2]=sin a, m[8]=-sin a, m[10]=cos a`
- 繞 X 軸:`m[5]=cos a, m[6]=-sin a, m[9]=sin a, m[10]=cos a`

**加分小題(yaw / pitch / roll):** 在 Y 軸朝上的座標系中,

- `RotY` 是 **yaw**(左右轉頭)
- `RotX` 是 **pitch**(上下點頭)
- `RotZ` 是 **roll**(左右翻滾)

### 2. Model 矩陣(GameObject.localToWorld)

```java
return Matrix4.Trans(transform.position)
        .mult(Matrix4.RotY(transform.rotation.y))
        .mult(Matrix4.RotX(transform.rotation.x))
        .mult(Matrix4.RotZ(transform.rotation.z))
        .mult(Matrix4.Scale(transform.scale));
```

點會依序經過縮放、旋轉(Z、X、Y)、平移。旋轉順序對應上面的 roll、pitch、yaw。

### 3. View 矩陣(Camera.setPositionOrientation)

由相機位置 `pos` 與注視點 `lookat` 建立相機座標系:

1. `forward = normalize(lookat - pos)`
2. `right = normalize(forward × (0,1,0))`;若 forward 與 up 平行(長度接近 0),改用 `(1,0,0)`
3. `up = right × forward`

View 矩陣的前三列依序是 `right`、`up`、`-forward`,平移欄是 `-dot(軸, pos)`。相機在 view space 中位於原點,朝 -Z 看(右手座標系)。

### 4. Projection 矩陣(Camera.setSize)

採用 OpenGL 形式的透視投影,`t = 1 / tan(fov / 2)`,`aspect = w / h`:

```
m[0]  =  t / aspect
m[5]  = -t                       // 螢幕 y 軸朝下,取負號避免畫面上下顛倒
m[10] = -(f + n) / (f - n)
m[11] = -2 f n / (f - n)
m[14] = -1                       // 讓 w = -z_view,以便透視除法
```

經過 MVP 與除以 w 之後,可見範圍會落在 NDC 的 `[-1, 1]^3`。

### 5. Depth buffer(getDepth、GameObject.Draw)

`getDepth` 以螢幕座標 `(x, y)` 對三角形三個頂點求重心座標 `(w1, w2, w3)`,再插值 `z = w1·A.z + w2·B.z + w3·C.z`。透視除法後的 NDC z 在螢幕空間中是線性的,所以可以直接用螢幕空間的重心座標插值。

`Draw()` 的流程:

1. 每個三角形經過 vertex shader(MVP)後做透視除法。
2. 求外框盒,只在盒子內逐像素以 `pnpoly` 判斷是否在三角形內(取像素中心)。
3. 用 `getDepth` 算出深度,若 `z` 超出 `[-1, 1]` 或不比 `GH_DEPTH[index]` 近就跳過。
4. 通過測試才執行 fragment shader,並更新深度緩衝與顏色。

**討論:為什麼深度圖看起來不明顯?**

NDC z 與實際距離不是線性關係,大部分精度集中在 near plane 附近。本作業 near = 0.1、far = 1000,物體大約在距離 10 的位置,NDC z 幾乎都落在 0.98 ~ 0.99。若直接當成灰階輸出,顏色約為 250 ~ 252,和背景 `color(250)` 幾乎一樣,所以看起來像什麼都沒畫。

解法是在 fragment shader 顯示時,把 NDC z 轉回線性距離再映射成灰階。深度測試仍然使用 NDC z:

```java
float zView = 2 * n * f / (f + n - z * (f - n));
float d = constrain(zView / 20.0, 0, 1);
```

### 6. 相機控制(cameraControl)

以 yaw / pitch 兩個角度表示相機朝向:

- `forward = (sin(yaw)·cos(pitch), sin(pitch), cos(yaw)·cos(pitch))`
- `right = (-cos(yaw), 0, sin(yaw))`

按鍵沿 forward、right 或世界 Y 軸移動,滑鼠拖曳改變 yaw / pitch。pitch 限制在 ±1.5 rad,避免視角翻轉。最後以 `lookat = pos + forward` 呼叫 `setPositionOrientation` 更新 view 矩陣。

**發現:** 原本只要按下滑鼠就會轉動視角,拖曳 Inspector 滑桿時鏡頭也會跟著亂轉。改成在 `mousePressed()` 中記錄按下時游標是否位於渲染區內,只有在渲染區內開始拖曳才轉動視角。

### 7. Backface culling(GameObject.debugDraw)

在 view space(相機位於原點)計算三角形法向量 `n = (b - a) × (c - a)`。若 `dot(n, a) >= 0`,代表法向量背對相機,就跳過不畫。

**發現:** 剔除的正確性依賴三角形繞序(逆時針為正面)。某些 obj 檔的三角形繞序不一致,會讓朝向相機的面被誤剔除,造成線框缺一角。因此在載入模型時加入 `fixWinding()`:

1. 以頂點座標建立邊與三角形的對應表。相鄰三角形共用的邊方向必須相反,否則就翻轉鄰居,讓整個 mesh 的繞序一致。
2. 計算有號體積 `Σ a · (b × c)`。若為負,代表法向量全部朝內,就整塊翻轉。

這個做法對凹多邊形模型也適用。

### 8. 其他處理

- **相機後方的頂點:** 頂點的 `w <= 0` 時,透視除法會讓座標翻轉,畫出錯誤的三角形或線段,因此在 `Draw()` 與 `debugDraw()` 中直接跳過這類三角形。這不是完整的 3D clipping。
- **CGLine:** 沿用 HW1 的 Bresenham 演算法。先以 Liang–Barsky 演算法把線段裁切到渲染區內,避免線框畫到 Inspector 面板,也避免座標過大時逐點迴圈跑太久。

## 截圖

### 位置: sketch_115522088_HW3/data/截圖


## LLM 使用說明

本次作業使用 Claude 輔助:

- 對照作業需求檢查程式。
- 協助修正以下問題:拖曳滑桿時鏡頭跟著轉動、深度圖不明顯、相機後方的三角形顯示錯誤、取消選檔時程式崩潰、obj 繞序不一致造成 culling 錯誤。
- 協助撰寫 Liang–Barsky 裁切、`fixWinding()` 與本 README。

`CGLine` 的 Bresenham 演算法為自己在 HW1 完成的程式碼。最後由我自行在 Processing 中執行並確認結果。
