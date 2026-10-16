public void CGLine(float x1, float y1, float x2, float y2) {
    // TODO HW1
    // (Bresenham's Line Algorithm)

    // Floating-point to Integer Conversion
    int ix1 = Math.round(x1), iy1 = Math.round(y1);
    int ix2 = Math.round(x2), iy2 = Math.round(y2);

    // 水平 / 垂直方向要走的總像素數（正數）
    int dx = Math.abs(ix2 - ix1);
    int dy = Math.abs(iy2 - iy1);

    // 決定 x、y 方向是往正向 (+1) 還是負向 (-1) 走
    int sx = (ix1 < ix2) ? 1 : -1;
    int sy = (iy1 < iy2) ? 1 : -1;

    // 誤差項
    int err = dx - dy;

    int x = ix1, y = iy1;
    int pink = color(255, 182, 193);

    while (true) {
        drawPoint(x, y, pink);
        if (x == ix2 && y == iy2) break;

        // 乘 2 避免小數運算
        int e2 = 2 * err;
        if (e2 > -dy) {
            err -= dy;
            x += sx;
        }
        if (e2 < dx) {
            err += dx;
            y += sy;
        }
    }

    /*
     stroke(0);
     noFill();
     line(x1,y1,x2,y2);
    */
}

public void CGCircle(float x, float y, float r) {
    // TODO HW1
    // (Midpoint Circle Algorithm)

    // Step1. 浮點數轉整數
    int cx = Math.round(x);       // 圓心 x
    int cy = Math.round(y);       // 圓心 y
    int radius = Math.round(r);   // 半徑

    // Step2. 初始化
    int xi = 0;
    int yi = radius;
    int d = 1 - radius;           // 決策參數

    // Step3. 顏色
    int circleColor = color(255, 182, 193);

    // Step4. 主迴圈：x <= y 時繼續（[修正] 原本是 xi < yi，會漏掉 45° 的點）
    do {
        // 八個對稱點（螢幕座標 y 向下）
        drawPoint(cx + xi, cy + yi, circleColor);  // 右下
        drawPoint(cx - xi, cy + yi, circleColor);  // 左下
        drawPoint(cx + xi, cy - yi, circleColor);  // 右上
        drawPoint(cx - xi, cy - yi, circleColor);  // 左上
        drawPoint(cx + yi, cy + xi, circleColor);  // 右下（x, y 互換）
        drawPoint(cx - yi, cy + xi, circleColor);  // 左下（x, y 互換）
        drawPoint(cx + yi, cy - xi, circleColor);  // 右上（x, y 互換）
        drawPoint(cx - yi, cy - xi, circleColor);  // 左上（x, y 互換）

        if (d < 0) {
            // 選 E：d = d + 2*xi + 3
            d = d + 2 * xi + 3;
        } else {
            // 選 SE：d = d + 2*(xi - yi) + 5
            d = d + 2 * (xi - yi) + 5;
            yi--;
        }
        xi++;

    } while (xi <= yi);

    /*
    stroke(0);
    noFill();
    circle(x,y,r*2);
    */
}

public void CGEllipse(float x, float y, float r1, float r2) {
    // TODO HW1
    // (Midpoint Ellipse Algorithm)

    // 1. 浮點數轉整數座標
    int cx = Math.round(x);
    int cy = Math.round(y);
    int rx = Math.round(r1);   // 水平半徑
    int ry = Math.round(r2);   // 垂直半徑

    // 2. 預先計算平方值（用 long 避免半徑較大時 int 溢位）
    long rx2 = (long) rx * rx;
    long ry2 = (long) ry * ry;
    long twoRx2 = 2 * rx2;
    long twoRy2 = 2 * ry2;

    // 3. 顏色
    int ellipseColor = color(255, 182, 193);

    // 4. 初始座標
    int xi = 0;
    int yi = ry;

    // =================================================================
    // 區域 1：斜率絕對值 < 1（x 變化較快）
    // =================================================================
    // 決策參數用 double，避免 rx2 / 4 的整數截斷誤差
    double p1 = ry2 - (double) rx2 * ry + 0.25 * rx2;
    long dx = twoRy2 * xi;   // 2 * ry^2 * x
    long dy = twoRx2 * yi;   // 2 * rx^2 * y

    while (dx < dy) {
        drawPoint(cx + xi, cy + yi, ellipseColor);  // 右下
        drawPoint(cx - xi, cy + yi, ellipseColor);  // 左下
        drawPoint(cx + xi, cy - yi, ellipseColor);  // 右上
        drawPoint(cx - xi, cy - yi, ellipseColor);  // 左上

        if (p1 < 0) {
            // 選 E
            xi++;
            dx += twoRy2;
            p1 += dx + ry2;
        } else {
            // 選 SE
            xi++;
            yi--;
            dx += twoRy2;
            dy -= twoRx2;
            p1 += dx - dy + ry2;
        }
    }

    // =================================================================
    // 區域 2：斜率絕對值 > 1（y 變化較快）
    // =================================================================
    // p2 = ry^2 * (x + 1/2)^2 + rx^2 * (y - 1)^2 - rx^2 * ry^2
    // [修正] 原本漏掉 ry^2 / 4，這裡直接用 (xi + 0.5) 計算
    double p2 = ry2 * (xi + 0.5) * (xi + 0.5)
              + rx2 * (double) (yi - 1) * (yi - 1)
              - (double) rx2 * ry2;

    // [修正] 原本是 yi > 0，會漏掉 yi == 0 的左右端點 (±rx, 0)
    while (yi >= 0) {
        drawPoint(cx + xi, cy + yi, ellipseColor);
        drawPoint(cx - xi, cy + yi, ellipseColor);
        drawPoint(cx + xi, cy - yi, ellipseColor);
        drawPoint(cx - xi, cy - yi, ellipseColor);

        if (p2 > 0) {
            // 選 S
            yi--;
            dy -= twoRx2;
            p2 += rx2 - dy;
        } else {
            // 選 SE
            yi--;
            xi++;
            dx += twoRy2;
            dy -= twoRx2;
            p2 += dx - dy + rx2;
        }
    }

    /*
    stroke(0);
    noFill();
    ellipse(x,y,r1*2,r2*2);
    */
}

public void CGCurve(Vector3 p1, Vector3 p2, Vector3 p3, Vector3 p4) {
    // TODO HW1
    // (Cubic Bezier Curve / De Casteljau's Algorithm)

    int curveColor = color(255, 182, 193);

    // 依控制點距離決定取樣步數
    float totalDistance = distance(p1, p2) + distance(p2, p3) + distance(p3, p4);
    // 曲線長度 <= 控制多邊形總長，所以步數取 2 倍距離，讓相鄰取樣點間距 < 1 像素，不會出現斷點
    int steps = max(50, (int) (totalDistance * 2));
    steps = min(steps, 5000);

    float stepSize = 1.0 / steps;

    for (int i = 0; i <= steps; i++) {
        float t = i * stepSize;

        // 第一層插值
        float q1x = (1 - t) * p1.x + t * p2.x;
        float q1y = (1 - t) * p1.y + t * p2.y;
        float q2x = (1 - t) * p2.x + t * p3.x;
        float q2y = (1 - t) * p2.y + t * p3.y;
        float q3x = (1 - t) * p3.x + t * p4.x;
        float q3y = (1 - t) * p3.y + t * p4.y;

        // 第二層插值
        float r1x = (1 - t) * q1x + t * q2x;
        float r1y = (1 - t) * q1y + t * q2y;
        float r2x = (1 - t) * q2x + t * q3x;
        float r2y = (1 - t) * q2y + t * q3y;

        // 第三層插值：曲線上的點
        float bezierX = (1 - t) * r1x + t * r2x;
        float bezierY = (1 - t) * r1y + t * r2y;

        // [修正] 四捨五入到整數像素再畫
        drawPoint(Math.round(bezierX), Math.round(bezierY), curveColor);
    }

    /*
    stroke(0);
    noFill();
    bezier(p1.x,p1.y,p2.x,p2.y,p3.x,p3.y,p4.x,p4.y);
    */
}

public void CGEraser(Vector3 p1, Vector3 p2) {
    // TODO HW1
    // 擦除 p1、p2 定義的矩形區域，背景色為 color(250)

    // Step 1: 矩形邊界，確保 x1 <= x2 且 y1 <= y2
    int x1 = int(min(p1.x, p2.x));
    int x2 = int(max(p1.x, p2.x));
    int y1 = int(min(p1.y, p2.y));
    int y2 = int(max(p1.y, p2.y));

    // [新增] 限制在畫布範圍內，避免處理畫布外的像素
    x1 = max(0, x1);
    y1 = max(0, y1);
    x2 = min(width - 1, x2);
    y2 = min(height - 1, y2);

    int bg = color(250);

    // Step 2: 逐像素設為背景色
    for (int x = x1; x <= x2; x++) {
        for (int y = y1; y <= y2; y++) {
            drawPoint(x, y, bg);
        }
    }
}

public void drawPoint(float x, float y, color c) {
    stroke(c);
    point(x, y);
}

public float distance(Vector3 a, Vector3 b) {
    Vector3 c = a.sub(b);
    return sqrt(Vector3.dot(c, c));
}
