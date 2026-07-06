#version 440

layout(location = 0) in vec4 qt_Vertex;
layout(location = 1) in vec2 qt_MultiTexCoord0;

layout(location = 0) out vec2 qt_TexCoord0;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float resW;
    float resH;
    float barCx;
    float barCy;
    float barHw;
    float barHh;
    float popupCx;
    float popupCy;
    float popupHw;
    float popupHh;
    float barRadius;
    float popupRadius;
    float smoothFactor;
    vec4 color;
};

void main() {
    qt_TexCoord0 = qt_MultiTexCoord0;
    gl_Position = qt_Matrix * qt_Vertex;
}
