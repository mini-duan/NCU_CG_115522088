public void CGLine(float x1, float y1, float x2, float y2) {
    // TODO HW1
    // (Bresenham's Line Algorithm)

    // [HW3 新增] 先用 Liang–Barsky 將線段裁切到渲染區內
    float[] seg = clipToRenderer(x1, y1, x2, y2);
    if (seg == null) return;   // 整條線都在渲染區外
    x1 = seg[0]; y1 = seg[1];
    x2 = seg[2]; y2 = seg[3];

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

// [HW3 新增] Liang–Barsky:把線段裁切到渲染區矩形內,完全在外面回傳 null
float[] clipToRenderer(float x1, float y1, float x2, float y2) {
    float xmin = renderer_size.x, ymin = renderer_size.y;
    float xmax = renderer_size.z - 1, ymax = renderer_size.w - 1;
    float dx = x2 - x1, dy = y2 - y1;
    float[] p = { -dx, dx, -dy, dy };
    float[] q = { x1 - xmin, xmax - x1, y1 - ymin, ymax - y1 };
    float t0 = 0, t1 = 1;
    for (int i = 0; i < 4; i++) {
        if (p[i] == 0) {
            if (q[i] < 0) return null;            // 平行且在外側
        } else {
            float t = q[i] / p[i];
            if (p[i] < 0) { if (t > t1) return null; if (t > t0) t0 = t; }
            else          { if (t < t0) return null; if (t < t1) t1 = t; }
        }
    }
    return new float[] { x1 + t0 * dx, y1 + t0 * dy, x1 + t1 * dx, y1 + t1 * dy };
}

public boolean outOfBoundary(float x, float y) {
    if (x < 0 || x >= width || y < 0 || y >= height)
        return true;
    return false;
}

public void drawPoint(float x, float y, color c) {
    if (outOfBoundary(x, y)) return;
    stroke(c);
    point(x, y);
}

public float distance(Vector3 a, Vector3 b) {
    Vector3 c = a.sub(b);
    return sqrt(Vector3.dot(c, c));
}

// 射線法 (crossing number)
boolean pnpoly(float x, float y, Vector3[] vertexes) {
    int n = vertexes.length;
    boolean inside = false;
    for (int i = 0, j = n - 1; i < n; j = i++) {
        Vector3 a = vertexes[i], b = vertexes[j];
        if ((a.y > y) != (b.y > y) &&
            x < (b.x - a.x) * (y - a.y) / (b.y - a.y) + a.x) {
            inside = !inside;
        }
    }
    return inside;
}

public Vector3[] findBoundBox(Vector3[] v) {
    if (v.length == 0) {
        return new Vector3[] { new Vector3(0), new Vector3(-1) }; // 空圖形:迴圈不會執行
    }
    float minX = v[0].x, minY = v[0].y, maxX = v[0].x, maxY = v[0].y;
    for (int i = 1; i < v.length; i++) {
        minX = min(minX, v[i].x);
        minY = min(minY, v[i].y);
        maxX = max(maxX, v[i].x);
        maxY = max(maxY, v[i].y);
    }
    return new Vector3[] { new Vector3(minX, minY, 0), new Vector3(maxX, maxY, 0) };
}

// 2D 外積 (AB x AP)
float cross2(Vector3 a, Vector3 b, Vector3 p) {
    return (b.x - a.x) * (p.y - a.y) - (b.y - a.y) * (p.x - a.x);
}

public Vector3[] Sutherland_Hodgman_algorithm(Vector3[] points, Vector3[] boundary) {
    ArrayList<Vector3> input = new ArrayList<Vector3>();
    ArrayList<Vector3> output = new ArrayList<Vector3>();
    for (int i = 0; i < points.length; i += 1) {
        input.add(points[i]);
    }

    // 用邊界的有號面積判斷順/逆時針,讓「內側」的判斷與邊界頂點順序無關
    float area = 0;
    for (int i = 0; i < boundary.length; i++) {
        Vector3 p = boundary[i], q = boundary[(i + 1) % boundary.length];
        area += p.x * q.y - q.x * p.y;
    }
    float s = (area >= 0) ? 1 : -1;

    output = input;
    for (int e = 0; e < boundary.length; e++) {
        Vector3 A = boundary[e];
        Vector3 B = boundary[(e + 1) % boundary.length];

        input = output;
        output = new ArrayList<Vector3>();
        if (input.size() == 0) break;

        Vector3 S = input.get(input.size() - 1);
        for (int i = 0; i < input.size(); i++) {
            Vector3 E = input.get(i);
            float cs = s * cross2(A, B, S);
            float ce = s * cross2(A, B, E);
            boolean sIn = cs >= 0, eIn = ce >= 0;

            if (eIn) {
                if (!sIn) output.add(intersect(S, E, cs, ce));
                output.add(E);
            } else if (sIn) {
                output.add(intersect(S, E, cs, ce));
            }
            S = E;
        }
    }

    Vector3[] result = new Vector3[output.size()];
    for (int i = 0; i < result.length; i += 1) {
        result[i] = output.get(i);
    }
    return result;
}

// S→E 與邊界線的交點,cs/ce 為 S、E 到邊界線的有號距離量
Vector3 intersect(Vector3 S, Vector3 E, float cs, float ce) {
    float t = cs / (cs - ce);
    return new Vector3(S.x + t * (E.x - S.x),
                       S.y + t * (E.y - S.y),
                       S.z + t * (E.z - S.z));
}

// HW3: 以螢幕 (x, y) 對三角形算重心座標,再插值 z
public float getDepth(float x, float y, Vector3[] vertex) {
    Vector3 A = vertex[0], B = vertex[1], C = vertex[2];
    float det = (B.y - C.y) * (A.x - C.x) + (C.x - B.x) * (A.y - C.y);
    if (abs(det) < 1e-8) return Float.MAX_VALUE; // 退化三角形,當作最遠
    float w1 = ((B.y - C.y) * (x - C.x) + (C.x - B.x) * (y - C.y)) / det;
    float w2 = ((C.y - A.y) * (x - C.x) + (A.x - C.x) * (y - C.y)) / det;
    float w3 = 1.0 - w1 - w2;
    return w1 * A.z + w2 * B.z + w3 * C.z;
}

float[] barycentric(Vector3 P, Vector4[] verts) {

    Vector3 A = verts[0].homogenized();
    Vector3 B = verts[1].homogenized();
    Vector3 C = verts[2].homogenized();

    // TODO HW4
    // Calculate the barycentric coordinates of point P in the triangle verts using
    // the barycentric coordinate system.

    float[] result = { 0.0, 0.0, 0.0 };

    return result;
}
