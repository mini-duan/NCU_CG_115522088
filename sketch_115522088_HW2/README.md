# Lab 2: 2D Rasterization Engine

學號:115522088

## 完成項目

| 項目 | 函式 | 檔案 | 狀態 |
|---|---|---|---|
| 平移矩陣 | `Matrix4.makeTrans` | `Matrix4.pde` | 完成 |
| Z 軸旋轉矩陣 | `Matrix4.makeRotZ` | `Matrix4.pde` | 完成 |
| 縮放矩陣 | `Matrix4.makeScale` | `Matrix4.pde` | 完成 |
| 點在多邊形內判斷 | `pnpoly` | `util.pde` | 完成 |
| 外框盒 | `findBoundBox` | `util.pde` | 完成 |
| Sutherland-Hodgman 裁切 | `Sutherland_Hodgman_algorithm` | `util.pde` | 完成 |
| (前置)直線繪製 | `CGLine`(沿用 HW1,Bresenham) | `util.pde` | 完成 |
| (加分)SSAA | - | - | 未實作 |

未使用任何被禁止的內建繪圖函式(`line`、`circle`、`ellipse`、`bezier`、`rect`、`beginShape`、`vertex`、`endShape`),也未使用外部函式庫。

## 執行方式

1. 用 Processing 開啟 `sketch_115522088_HW2/sketch_115522088_HW2.pde`。
2. 確認 `data/star.png` 存在。
3. 按 Run。點左上角的方形或星形按鈕新增圖形,再點中間 Hierarchy 的項目,用右側 Inspector 的滑桿調整 position、rotation、scale。

## 各項目做法

### 1. 變換矩陣(`Matrix4.pde`)

引擎採用 4x4 矩陣、列優先陣列 `m[16]`,與列向量相乘(`M * v`),所以平移量放在 `m[3]`、`m[7]`、`m[11]`。三個函式都先 `makeIdentity()`,再填入對應的元素。

- 平移:`m[3]=t.x, m[7]=t.y, m[11]=t.z`
- Z 軸旋轉:`m[0]=cos a, m[1]=-sin a, m[4]=sin a, m[5]=cos a`
- 縮放:`m[0]=s.x, m[5]=s.y, m[10]=s.z`

`Shape.localToWorld()` 以 `Trans * RotZ * Scale` 的順序組合,因此點會先縮放、再旋轉、最後平移。

心得:畫面座標的 y 軸朝下,所以 rotation z 往正方向調整時,圖形看起來是順時針旋轉。

### 2. 點在多邊形內判斷(`pnpoly`)

使用射線法(crossing number):從測試點往右發射一條水平射線,計算與多邊形各邊的交點數,奇數次表示在內部。對每條邊 (a, b),先檢查 `(a.y > y) != (b.y > y)`,表示該邊跨越測試點的水平線,再檢查測試點的 x 是否小於交點的 x,符合就翻轉 `inside`。

這個條件保證 `b.y - a.y` 不為 0,不會除以 0,也能正確處理星形這種凹多邊形。

### 3. 外框盒(`findBoundBox`)

走訪所有頂點,記錄最小與最大的 x、y,回傳 `{min, max}` 兩個 `Vector3`。`Shape.drawShape()` 只在這個盒子內逐像素呼叫 `pnpoly`,而不是掃描整個畫布,可大幅減少運算量。若頂點陣列為空(圖形被完全裁掉),回傳一個空盒子,讓迴圈不會執行。

### 4. Sutherland-Hodgman 裁切(`Sutherland_Hodgman_algorithm`)

依序對邊界的每一條邊裁切一次,前一輪的輸出是下一輪的輸入。對每條邊 A→B 與輸入多邊形的每條線段 S→E:

| S | E | 輸出 |
|---|---|---|
| 內 | 內 | E |
| 外 | 內 | 交點、E |
| 內 | 外 | 交點 |
| 外 | 外 | 無 |

「在內側」用 2D 外積 `cross(B-A, P-A)` 的正負判斷。為了不依賴邊界頂點的順序,先用邊界的有號面積判斷順時針或逆時針,再決定哪一側是內側。交點以 `t = cs / (cs - ce)` 線性內插求得,其中 `cs`、`ce` 是 S、E 到邊界線的有號距離量。

心得:凹多邊形(星形)被裁切時,可能在邊界上產生相連的退化邊,這是此演算法的已知限制,對填色結果沒有影響。

## LLM 使用說明

本次作業使用 Claude 輔助:協助理解作業需求與 Processing 專案的開啟方式、撰寫與檢查 `Matrix4`、`pnpoly`、`findBoundBox`、`Sutherland_Hodgman_algorithm` 的實作。`CGLine` 為自己在 HW1 完成的程式碼。最後由我自行在 Processing 中執行並確認結果。
