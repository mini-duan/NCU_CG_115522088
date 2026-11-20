import javax.swing.JFileChooser;
import javax.swing.filechooser.FileNameExtensionFilter;

public Vector4 renderer_size;
static public float GH_FOV = 45.0f;
static public float GH_NEAR_MIN = 1e-3f;
static public float GH_NEAR_MAX = 1e-1f;
static public float GH_FAR = 1000.0f;

public boolean debug = false;

public float[] GH_DEPTH;
public PImage renderBuffer;

Engine engine;
Camera main_camera;
Vector3 cam_position;
Vector3 lookat;
float cam_yaw = 0, cam_pitch = 0;
boolean camDragging = false;   // 只有在渲染區內按下滑鼠才轉鏡頭

void setup() {
    size(1000, 600);
    renderer_size = new Vector4(20, 50, 520, 550);
    cam_position = new Vector3(0, 0, -10);
    lookat = new Vector3(0, 0, 0);
    setDepthBuffer();
    main_camera = new Camera();
    engine = new Engine();
}

void setDepthBuffer() {
    renderBuffer = new PImage(int(renderer_size.z - renderer_size.x), int(renderer_size.w - renderer_size.y));
    GH_DEPTH = new float[int(renderer_size.z - renderer_size.x) * int(renderer_size.w - renderer_size.y)];
    for (int i = 0; i < GH_DEPTH.length; i++) {
        GH_DEPTH[i] = 1.0;
        renderBuffer.pixels[i] = color(1.0 * 250);
    }
}

void draw() {
    background(255);

    engine.run();
    cameraControl();
}

void mousePressed() {
    camDragging = mouseX >= renderer_size.x && mouseX <= renderer_size.z &&
                  mouseY >= renderer_size.y && mouseY <= renderer_size.w;
}

void mouseReleased() {
    camDragging = false;
}

String selectFile() {
    JFileChooser fileChooser = new JFileChooser();
    fileChooser.setCurrentDirectory(new File("."));
    fileChooser.setFileSelectionMode(JFileChooser.FILES_ONLY);
    FileNameExtensionFilter filter = new FileNameExtensionFilter("Obj Files", "obj");
    fileChooser.setFileFilter(filter);

    int result = fileChooser.showOpenDialog(null);
    if (result == JFileChooser.APPROVE_OPTION) {
        String filePath = fileChooser.getSelectedFile().getAbsolutePath();
        return filePath;
    }
    return "";
}

void cameraControl() {
    float speed = 0.2, turn = 0.005;

    // 滑鼠在渲染區內拖曳:轉動視角(拖滑桿、點按鈕時不會轉)
    if (mousePressed && camDragging) {
        cam_yaw   -= (mouseX - pmouseX) * turn;
        cam_pitch -= (mouseY - pmouseY) * turn;
        cam_pitch = constrain(cam_pitch, -1.5, 1.5);
    }

    float fx = sin(cam_yaw) * cos(cam_pitch);
    float fy = sin(cam_pitch);
    float fz = cos(cam_yaw) * cos(cam_pitch);
    float rx = -cos(cam_yaw), rz = sin(cam_yaw);

    // W/S 前後,A/D 左右,Q/E 下上
    if (keyPressed) {
        if (key == 'w' || key == 'W') { cam_position.x += fx*speed; cam_position.y += fy*speed; cam_position.z += fz*speed; }
        if (key == 's' || key == 'S') { cam_position.x -= fx*speed; cam_position.y -= fy*speed; cam_position.z -= fz*speed; }
        if (key == 'd' || key == 'D') { cam_position.x += rx*speed; cam_position.z += rz*speed; }
        if (key == 'a' || key == 'A') { cam_position.x -= rx*speed; cam_position.z -= rz*speed; }
        if (key == 'e' || key == 'E') cam_position.y += speed;
        if (key == 'q' || key == 'Q') cam_position.y -= speed;
    }

    lookat = new Vector3(cam_position.x + fx, cam_position.y + fy, cam_position.z + fz);
    main_camera.setPositionOrientation(cam_position, lookat);
}
