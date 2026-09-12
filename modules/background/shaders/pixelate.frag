#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    vec2 resolution;
};

layout(binding = 1) uniform sampler2D source;

void main() {
    // Blocky in the middle of the transition, sharp at both ends
    const float maxBlock = 48.0;
    float block = maxBlock * sin(progress * 3.14159265);

    vec2 uv = qt_TexCoord0;
    if (block > 1.0 && resolution.x > 0.0 && resolution.y > 0.0) {
        vec2 grid = max(resolution / block, vec2(1.0));
        uv = (floor(uv * grid) + 0.5) / grid;
    }

    vec4 color = texture(source, uv);
    fragColor = color * progress * qt_Opacity;
}
