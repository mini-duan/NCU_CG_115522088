public void CGLine(float x1, float y1, float x2, float y2) {
    int ix1 = Math.round(x1), iy1 = Math.round(y1);
    int ix2 = Math.round(x2), iy2 = Math.round(y2);

    int dx = Math.abs(ix2 - ix1);
    int dy = Math.abs(iy2 - iy1);
    int sx = (ix1 < ix2) ? 1 : -1;
    int sy = (iy1 < iy2) ? 1 : -1;
    int err = dx - dy;

    int x = ix1, y = iy1;
    int pink = color(255, 182, 193);

    while (true) {
        drawPoint(x, y, pink);
        if (x == ix2 && y == iy2) break;
        int e2 = 2 * err;
        if (e2 > -dy) { err -= dy; x += sx; }
        if (e2 < dx)  { err += dx; y += sy; }
    }
}

public boolean outOfBoundary(float x, float y) {
    if (x < 0 || x >= width || y < 0 || y >= height)
        return true;
    return false;
}

public void drawPoint(float x, float y, color c) {
    int index = (int) y * width + (int) x;
    if (outOfBoundary(x, y))
        return;
    pixels[index] = c;
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
