# CG Assignment - Lab 1

**學號：** 115522088

本作業實作了小畫家程式中缺少的五個核心演算法，全部位於 `util.pde`。每個圖形都只透過 `drawPoint(x, y, color)` 在像素層級逐點繪製，沒有使用 `line`、`circle`、`ellipse`、`bezier`、`rect`、`beginShape`、`vertex`、`endShape` 等被禁止的內建函式（驗證用的呼叫皆已註解），也沒有使用外部函式庫。

## 完成項目

| 任務 | 函式 | 使用演算法 | 狀態 |
|---|---|---|---|
| 直線 | `CGLine` | Bresenham 直線演算法 | 完成 |
| 圓形 | `CGCircle` | 中點圓演算法 | 完成 |
| 橢圓 | `CGEllipse` | 中點橢圓演算法 | 完成 |
| 曲線 | `CGCurve` | De Casteljau 演算法（三次貝茲曲線） | 完成 |
| 橡皮擦 | `CGEraser` | 矩形區域像素重置 | 完成 |
| Bonus | - | - | 未實作 |

## 演算法實作說明

### 1. CGLine 直線繪製

**實作演算法：** Bresenham 直線演算法

**演算法特色**

- **純整數運算**：先把輸入座標四捨五入成整數像素，之後完全不使用浮點數。
- **八方向通用**：用 `sx`、`sy` 記錄前進方向（+1 或 -1），同一份程式碼可以處理任何斜率與方向的直線。
- **避免小數**：誤差項乘以 2 後再比較，不需要處理 0.5 這種小數。

**技術實作重點**

```java
int err = dx - dy;          // 誤差項
while (true) {
    drawPoint(x, y, pink);
    if (x == ix2 && y == iy2) break;

    int e2 = 2 * err;
    if (e2 > -dy) { err -= dy; x += sx; }   // 往 x 方向前進
    if (e2 < dx)  { err += dx; y += sy; }   // 往 y 方向前進
}
```

**參數說明**

- `x1, y1`：起點座標
- `x2, y2`：終點座標
- 輸出：粉色的像素直線

多邊形與鉛筆都是以 `CGLine` 為基礎，直線完成後它們也能正常運作。

### 2. CGCircle 圓形繪製

**實作演算法：** 中點圓演算法（Midpoint Circle Algorithm）

**演算法特色**

- **八方對稱**：只計算 1/8 圓弧，每個點再鏡射到八個位置。
- **整數決策參數**：用 `d = 1 - r` 判斷下一個像素，沒有浮點誤差。
- **不漏點**：迴圈條件為 `xi <= yi`，45 度對角線上的點也會被畫出。

**技術實作重點**

```java
do {
    // 八個對稱點（螢幕座標 y 向下）
    drawPoint(cx + xi, cy + yi, circleColor);  // 右下
    drawPoint(cx - xi, cy + yi, circleColor);  // 左下
    drawPoint(cx + xi, cy - yi, circleColor);  // 右上
    drawPoint(cx - xi, cy - yi, circleColor);  // 左上
    drawPoint(cx + yi, cy + xi, circleColor);  // x、y 互換的四個點
    drawPoint(cx - yi, cy + xi, circleColor);
    drawPoint(cx + yi, cy - xi, circleColor);
    drawPoint(cx - yi, cy - xi, circleColor);

    if (d < 0) { d = d + 2 * xi + 3; }                      // 選 E
    else       { d = d + 2 * (xi - yi) + 5; yi--; }         // 選 SE
    xi++;
} while (xi <= yi);
```

**參數說明**

- `x, y`：圓心座標
- `r`：半徑
- 輸出：粉色圓形輪廓

### 3. CGEllipse 橢圓繪製

**實作演算法：** 中點橢圓演算法（Midpoint Ellipse Algorithm）

**演算法特色**

- **雙區域處理**：以斜率 = -1 的位置為界，分成平緩（區域 1）與陡峭（區域 2）兩段，各自選擇最適合的前進方向。
- **四方對稱**：只計算第一象限，其餘三個象限用鏡射取得。
- **累加更新**：`dx = 2*ry²*x`、`dy = 2*rx²*y` 每步只做加減法，迴圈內不重複乘法。
- **精度處理**：決策參數用 `double`，平方值用 `long`，避免 `rx²/4` 被整數除法截斷，也避免半徑較大時溢位。

**技術實作重點**

```java
// 區域 1：斜率絕對值 < 1，x 為主要前進方向
while (dx < dy) {
    // 畫四個對稱點，p1 < 0 選 E，否則選 SE
}

// 區域 2：斜率絕對值 >= 1，y 為主要前進方向
double p2 = ry2 * (xi + 0.5) * (xi + 0.5)
          + rx2 * (double)(yi - 1) * (yi - 1) - (double) rx2 * ry2;
while (yi >= 0) {
    // 畫四個對稱點，p2 > 0 選 S，否則選 SE
}
```

區域 2 跑到 `yi >= 0`，才能把左右端點 `(±rx, 0)` 畫出來。

**參數說明**

- `x, y`：橢圓中心座標
- `r1`：水平半徑
- `r2`：垂直半徑
- 輸出：橢圓輪廓

### 4. CGCurve 貝茲曲線繪製

**實作演算法：** De Casteljau 演算法

**演算法特色**

- **數值穩定**：不直接展開三次多項式，只用重複的線性插值求點。
- **三層插值**：控制點 → 三個 Q 點 → 兩個 R 點 → 曲線上的點。
- **自動調整取樣密度**：曲線長度不會超過控制多邊形，所以取 `steps = 2 * (|P1P2| + |P2P3| + |P3P4|)`（最少 50、最多 5000 步），相鄰取樣點間距小於 1 像素，曲線不會斷開。
- **對齊像素**：每個點先四捨五入再繪製。

**技術實作重點**

```java
// 第一層：相鄰控制點之間插值
float q1x = (1 - t) * p1.x + t * p2.x;
float q2x = (1 - t) * p2.x + t * p3.x;
float q3x = (1 - t) * p3.x + t * p4.x;

// 第二層：第一層結果之間插值
float r1x = (1 - t) * q1x + t * q2x;
float r2x = (1 - t) * q2x + t * q3x;

// 第三層：得到曲線上的點（y 座標做法相同）
float bezierX = (1 - t) * r1x + t * r2x;
```

**參數說明**

- `p1`：起點（曲線經過）
- `p2`：第一控制點（決定起點的切線方向）
- `p3`：第二控制點（決定終點的切線方向）
- `p4`：終點（曲線經過）
- 輸出：平滑的三次貝茲曲線

### 5. CGEraser 區域擦除

**實作方法：** 把矩形區域內的像素重設為背景色

**功能特色**

- **任意對角點**：用 `min` / `max` 整理邊界，`p1`、`p2` 不論順序都能得到正確矩形。
- **限制在畫布內**：邊界限制在 `0..width-1`、`0..height-1`，避免處理畫布外的座標。
- **還原背景色**：範圍內每個像素都設為背景色 `color(250)`。

**技術實作重點**

```java
int x1 = max(0, int(min(p1.x, p2.x)));
int x2 = min(width - 1, int(max(p1.x, p2.x)));
int y1 = max(0, int(min(p1.y, p2.y)));
int y2 = min(height - 1, int(max(p1.y, p2.y)));

for (int x = x1; x <= x2; x++) {
    for (int y = y1; y <= y2; y++) {
        drawPoint(x, y, color(250));
    }
}
```

**參數說明**

- `p1`：擦除區域的一個角點
- `p2`：擦除區域的對角點

## 開發過程中的發現

- 圓的迴圈一開始寫成 `xi < yi`，45 度對角線上會有小缺口，改成 `xi <= yi` 後解決。
- 橢圓區域 2 的初始決策參數如果漏掉 `ry²/4`，或迴圈寫成 `yi > 0`，兩個區域的交界與左右端點都會出現誤差。
- 曲線取樣太稀疏時，又長又接近直線的貝茲曲線會變成一點一點的虛線，所以把步數和控制多邊形長度綁在一起。

## 演算法參考

- Bresenham's Line Algorithm (1965)
- Midpoint Circle Algorithm
- Midpoint Ellipse Algorithm
- De Casteljau's Algorithm - Paul de Casteljau (1959)

## 工具與 LLM 使用說明

使用 Claude（Anthropic）作為程式碼檢查與文件撰寫的輔助工具。請 Claude 協助找出 bug 並說明原因，包含圓與橢圓的迴圈條件、橢圓區域 2 的初始值、曲線取樣過疏，以及橡皮擦未限制畫布範圍。我閱讀並理解這些說明後自行套用修正，並在 Processing 中實際測試。