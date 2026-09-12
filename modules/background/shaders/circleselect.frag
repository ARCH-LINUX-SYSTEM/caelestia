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

    // Aspect-correct distance from centre so the reveal is a true circle
    vec2 aspect = resolution.x > 0.0 && resolution.y > 0.0 ? vec2(resolution.x / resolution.y, 1.0) : vec2(1.0);
    vec2 uv = (qt_TexCoord0 - 0.5) * aspect;

    // Radius needed to fully cover the corners at progress = 1
    float maxRadius = length(0.5 * aspect);
    float radius = progress * maxRadius;

    float dist = length(uv);
    float mask = 1.0 - smoothstep(radius - 0.015, radius + 0.015, dist);

    fragColor = color * mask * qt_Opacity;
}
