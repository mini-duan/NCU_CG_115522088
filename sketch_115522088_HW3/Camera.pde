public class Camera {
    Matrix4 projection = new Matrix4();
    Matrix4 worldView = new Matrix4();
    int wid;
    int hei;
    float near;
    float far;
    Transform transform;

    Camera() {
        wid = 256;
        hei = 256;
        worldView.makeIdentity();
        projection.makeIdentity();
        transform = new Transform();
    }

    Matrix4 inverseProjection() {
        Matrix4 invProjection = Matrix4.Zero();
        float a = projection.m[0];
        float b = projection.m[5];
        float c = projection.m[10];
        float d = projection.m[11];
        float e = projection.m[14];
        invProjection.m[0] = 1.0f / a;
        invProjection.m[5] = 1.0f / b;
        invProjection.m[11] = 1.0f / e;
        invProjection.m[14] = 1.0f / d;
        invProjection.m[15] = -c / (d * e);
        return invProjection;
    }

    Matrix4 Matrix() {
        return projection.mult(worldView);
    }

    void setSize(int w, int h, float n, float f) {
        wid = w;
        hei = h;
        near = n;
        far = f;

        float aspect = (float) w / h;
        float t = 1.0f / tan(radians(GH_FOV) / 2.0f);

        projection = new Matrix4();            // 全 0
        projection.m[0]  = t / aspect;
        projection.m[5]  = -t;                 // 螢幕 y 向下,取負號讓畫面不會上下顛倒
        projection.m[10] = -(f + n) / (f - n);
        projection.m[11] = -2.0f * f * n / (f - n);
        projection.m[14] = -1.0f;
    }

    void setPositionOrientation(Vector3 pos, float rotX, float rotY) {

    }

    void setPositionOrientation(Vector3 pos, Vector3 lookat) {
        // forward
        float fx = lookat.x - pos.x, fy = lookat.y - pos.y, fz = lookat.z - pos.z;
        float fl = sqrt(fx*fx + fy*fy + fz*fz);
        fx /= fl; fy /= fl; fz /= fl;

        // right = forward x up(0,1,0)
        float rx = -fz, ry = 0, rz = fx;
        float rl = sqrt(rx*rx + rz*rz);
        if (rl < 1e-6f) { rx = 1; rz = 0; } else { rx /= rl; rz /= rl; }

        // up = right x forward
        float ux = ry*fz - rz*fy;
        float uy = rz*fx - rx*fz;
        float uz = rx*fy - ry*fx;

        worldView = new Matrix4();
        worldView.m[0]  = rx;  worldView.m[1]  = ry;  worldView.m[2]  = rz;  worldView.m[3]  = -(rx*pos.x + ry*pos.y + rz*pos.z);
        worldView.m[4]  = ux;  worldView.m[5]  = uy;  worldView.m[6]  = uz;  worldView.m[7]  = -(ux*pos.x + uy*pos.y + uz*pos.z);
        worldView.m[8]  = -fx; worldView.m[9]  = -fy; worldView.m[10] = -fz; worldView.m[11] = (fx*pos.x + fy*pos.y + fz*pos.z);
        worldView.m[15] = 1;
    }
}
