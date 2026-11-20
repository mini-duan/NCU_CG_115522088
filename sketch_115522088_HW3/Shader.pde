public class Shader {
    VertexShader vertex;
    FragmentShader fragment;

    public Shader(VertexShader v, FragmentShader f) {
        vertex = v;
        fragment = f;
    }
}

public abstract class VertexShader {
    abstract Vector4[] main(Object[] attribute, Object[] uniform);
}

public abstract class FragmentShader {
    abstract Vector4 main(Object[] varying);
}

public class DepthVertexShader extends VertexShader {
    Vector4[] main(Object[] attribute, Object[] uniform) {
        Vector3[] aVertexPosition = (Vector3[]) attribute[0];
        Matrix4 MVP = (Matrix4) uniform[0];
        Vector4[] result = new Vector4[3];
        for (int i = 0; i < result.length; i++) {
            result[i] = MVP.mult(aVertexPosition[i].getVector4(1.0));
        }
        return result;
    }
}

public class DepthFragmentShader extends FragmentShader {
    Vector4 main(Object[] varying) {
        Vector3 position = (Vector3) varying[0];

        // NDC z 非線性,中距離的物體 z 幾乎都接近 1(和背景一樣白)
        // 顯示時轉回線性距離;深度測試仍使用 NDC z
        float n = main_camera.near, f = main_camera.far;
        float zView = 2 * n * f / (f + n - position.z * (f - n));
        float d = constrain(zView / 20.0, 0, 1);   // 20 = 想觀察的距離範圍,可自行調整

        return new Vector4(d, d, d, 1.0);
    }
}
