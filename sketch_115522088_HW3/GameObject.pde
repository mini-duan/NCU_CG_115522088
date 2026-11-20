public class GameObject {
    Transform transform;
    Mesh mesh;
    String name;
    Shader shader;

    GameObject() {
        transform = new Transform();
    }

    GameObject(String fname) {
        transform = new Transform();
        setMesh(fname);
        fixWinding();   // 統一三角形繞序,讓 backface culling 正確
        // 同時支援 Windows / Mac / Linux 路徑
        name = new File(fname).getName().replaceFirst("(?i)\\.obj$", "");
        shader = new Shader(new DepthVertexShader(), new DepthFragmentShader());
    }

    void reset() {
        transform.position.setZero();
        transform.rotation.setZero();
        transform.scale.setOnes();
    }

    void setMesh(String fname) {
        mesh = new Mesh(fname);
    }

    // ===== 繞序修正 =====
    // 1. 相鄰三角形共用的邊方向必須相反,否則翻轉鄰居 → 整個 mesh 繞序一致
    // 2. 有號體積 < 0 代表法向量全部朝內 → 整塊翻轉
    void fixWinding() {
        int n = mesh.triangles.size();
        String[][] keys = new String[n][3];
        HashMap<String, ArrayList<Integer>> edgeMap = new HashMap<String, ArrayList<Integer>>();

        for (int i = 0; i < n; i++) {
            Triangle t = mesh.triangles.get(i);
            for (int j = 0; j < 3; j++) keys[i][j] = vkey(t.verts[j]);
            for (int j = 0; j < 3; j++) {
                String e = edgeKey(keys[i][j], keys[i][(j + 1) % 3]);
                ArrayList<Integer> list = edgeMap.get(e);
                if (list == null) { list = new ArrayList<Integer>(); edgeMap.put(e, list); }
                list.add(i);
            }
        }

        boolean[] visited = new boolean[n];
        for (int s = 0; s < n; s++) {
            if (visited[s]) continue;
            ArrayList<Integer> comp = new ArrayList<Integer>();
            ArrayList<Integer> stack = new ArrayList<Integer>();
            stack.add(s);
            visited[s] = true;

            while (!stack.isEmpty()) {
                int t = stack.remove(stack.size() - 1);
                comp.add(t);
                for (int j = 0; j < 3; j++) {
                    String a = keys[t][j], b = keys[t][(j + 1) % 3];
                    for (int u : edgeMap.get(edgeKey(a, b))) {
                        if (visited[u]) continue;
                        if (hasDirectedEdge(keys[u], a, b)) flipTriangle(u, keys);  // 同方向 → 繞序相反
                        visited[u] = true;
                        stack.add(u);
                    }
                }
            }

            if (comp.size() >= 4) {
                float vol = 0;
                for (int t : comp) {
                    Vector3[] v = mesh.triangles.get(t).verts;
                    vol += Vector3.dot(v[0], Vector3.cross(v[1], v[2]));
                }
                if (vol < 0) for (int t : comp) flipTriangle(t, keys);
            }
        }
    }

    String vkey(Vector3 v) {
        return round(v.x * 1e4) + "," + round(v.y * 1e4) + "," + round(v.z * 1e4);
    }

    String edgeKey(String a, String b) {
        return a.compareTo(b) < 0 ? a + "|" + b : b + "|" + a;
    }

    boolean hasDirectedEdge(String[] k, String a, String b) {
        for (int j = 0; j < 3; j++)
            if (k[j].equals(a) && k[(j + 1) % 3].equals(b)) return true;
        return false;
    }

    void flipTriangle(int i, String[][] keys) {
        Triangle t = mesh.triangles.get(i);
        Vector3 tv = t.verts[1]; t.verts[1] = t.verts[2]; t.verts[2] = tv;
        Vector3 tu = t.uvs[1];   t.uvs[1] = t.uvs[2];     t.uvs[2] = tu;
        int ti = t.triangle[1];  t.triangle[1] = t.triangle[2]; t.triangle[2] = ti;
        String tk = keys[i][1];  keys[i][1] = keys[i][2]; keys[i][2] = tk;
        for (Vector3 nm : t.normal) if (nm != null) nm.product(-1);
    }

    void Draw() {
        Matrix4 MVP = main_camera.Matrix().mult(localToWorld());
        int W = int(renderer_size.z - renderer_size.x);
        int H = int(renderer_size.w - renderer_size.y);
        for (int i = 0; i < mesh.triangles.size(); i++) {
            Triangle triangle = mesh.triangles.get(i);
            Vector3[] position = triangle.verts;
            Vector4[] gl_Position = shader.vertex.main(new Object[]{position}, new Object[]{MVP});

            // 頂點在相機後方 (w <= 0) 時,除以 w 會翻轉座標,直接跳過
            if (gl_Position[0].w <= 0 || gl_Position[1].w <= 0 || gl_Position[2].w <= 0) continue;

            Vector3[] s_Position = new Vector3[3];
            for (int j = 0; j < gl_Position.length; j++) {
                s_Position[j] = gl_Position[j].homogenized();
            }
            Vector3[] boundbox = findBoundBox(s_Position);
            float minX = map(min(max(boundbox[0].x, -1.0), 1.0), -1.0, 1.0, 0.0, W);
            float maxX = map(min(max(boundbox[1].x, -1.0), 1.0), -1.0, 1.0, 0.0, W);
            float minY = map(min(max(boundbox[0].y, -1.0), 1.0), -1.0, 1.0, 0.0, H);
            float maxY = map(min(max(boundbox[1].y, -1.0), 1.0), -1.0, 1.0, 0.0, H);

            for (int y = int(minY); y < maxY && y < H; y++) {
                for (int x = int(minX); x < maxX && x < W; x++) {
                    float rx = map(x + 0.5, 0.0, W, -1, 1);   // 取像素中心
                    float ry = map(y + 0.5, 0.0, H, -1, 1);
                    if (!pnpoly(rx, ry, s_Position)) continue;
                    int index = y * W + x;

                    float z = getDepth(rx, ry, s_Position);
                    if (z < -1 || z > 1) continue;            // 超出 near / far
                    if (GH_DEPTH[index] <= z) continue;       // 先做深度測試再跑 fragment

                    Vector4 c = shader.fragment.main(new Object[]{new Vector3(rx, ry, z)});
                    GH_DEPTH[index] = z;
                    renderBuffer.pixels[index] = color(c.x * 255, c.y * 255, c.z * 255);
                }
            }
        }
        update();
    }

    void update() {
    }

    void debugDraw() {
        Matrix4 MVP = main_camera.Matrix().mult(localToWorld());
        Matrix4 MV  = main_camera.worldView.mult(localToWorld());
        for (int i = 0; i < mesh.triangles.size(); i++) {
            Triangle triangle = mesh.triangles.get(i);

            // Backculling:在 view space(相機在原點)判斷面是否背對相機
            Vector3 a = MV.MulPoint(triangle.verts[0]);
            Vector3 b = MV.MulPoint(triangle.verts[1]);
            Vector3 c = MV.MulPoint(triangle.verts[2]);
            float e1x = b.x - a.x, e1y = b.y - a.y, e1z = b.z - a.z;
            float e2x = c.x - a.x, e2y = c.y - a.y, e2z = c.z - a.z;
            float nx = e1y*e2z - e1z*e2y;
            float ny = e1z*e2x - e1x*e2z;
            float nz = e1x*e2y - e1y*e2x;
            if (nx*a.x + ny*a.y + nz*a.z >= 0) continue;   // 背面,跳過

            // 頂點在相機後方 (w <= 0) 時跳過,避免畫出翻轉的亂線
            Vector3[] img_pos = new Vector3[3];
            boolean behind = false;
            for (int j = 0; j < 3; j++) {
                Vector4 clip = MVP.mult(triangle.verts[j].getVector4(1.0));
                if (clip.w <= 0) { behind = true; break; }
                img_pos[j] = clip.homogenized();
            }
            if (behind) continue;

            for (int j = 0; j < img_pos.length; j++) {
                img_pos[j] = new Vector3(map(img_pos[j].x, -1, 1, renderer_size.x, renderer_size.z),
                        map(img_pos[j].y, -1, 1, renderer_size.y, renderer_size.w), img_pos[j].z);
            }

            CGLine(img_pos[0].x, img_pos[0].y, img_pos[1].x, img_pos[1].y);
            CGLine(img_pos[1].x, img_pos[1].y, img_pos[2].x, img_pos[2].y);
            CGLine(img_pos[2].x, img_pos[2].y, img_pos[0].x, img_pos[0].y);
        }
    }

    String getGameObjectName() {
        return name;
    }

    Matrix4 localToWorld() {
        return Matrix4.Trans(transform.position)
                .mult(Matrix4.RotY(transform.rotation.y))
                .mult(Matrix4.RotX(transform.rotation.x))
                .mult(Matrix4.RotZ(transform.rotation.z))
                .mult(Matrix4.Scale(transform.scale));
    }

    Matrix4 worldToLocal() {
        return Matrix4.Scale(transform.scale.inv()).mult(Matrix4.RotZ(-transform.rotation.z))
                .mult(Matrix4.RotX(-transform.rotation.x)).mult(Matrix4.RotY(-transform.rotation.y))
                .mult(Matrix4.Trans(transform.position.mult(-1)));
    }

    Vector3 forward() {
        // 與 localToWorld 相同的旋轉順序,取 -Z 軸為前方
        return (Matrix4.RotY(transform.rotation.y).mult(Matrix4.RotX(transform.rotation.x))
                .mult(Matrix4.RotZ(transform.rotation.z)).zAxis()).mult(-1);
    }
}
