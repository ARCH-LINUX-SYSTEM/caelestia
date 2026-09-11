#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float radius;
    vec2 center;
};

layout(binding = 1) uniform sampler2D source;

void main() {
    vec4 color = texture(source, qt_TexCoord0);

    // Calculate distance from center
    vec2 uv = qt_TexCoord0;
    float dist = distance(uv, center);

    // Create circle mask
    float circle = smoothstep(radius - 0.01, radius, dist);

    // Apply mask - show content inside circle, transparent outside
    fragColor = color * (1.0 - circle) * qt_Opacity;
}
