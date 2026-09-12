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
    vec4 color = texture(source, qt_TexCoord0);

    // t0 sweeps from just past the right edge (progress = 0, fully hidden)
    // to below the left edge (progress = 1, fully revealed).
    const float softness = 0.12;
    float t0 = (1.0 + softness) - progress * (1.0 + 3.0 * softness);
    float t1 = t0 + 2.0 * softness;
    float mask = smoothstep(t0, t1, qt_TexCoord0.x);

    fragColor = color * mask * qt_Opacity;
}
