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

    // Aspect-correct distance from centre
    vec2 aspect = resolution.x > 0.0 && resolution.y > 0.0 ? vec2(resolution.x / resolution.y, 1.0) : vec2(1.0);
    vec2 uv = (qt_TexCoord0 - 0.5) * aspect;

    float maxRadius = length(0.5 * aspect);
    // Reveal from the outer edges inward, closing in on the centre "pit"
    float radius = (1.0 - progress) * maxRadius;

    float dist = length(uv);
    float mask = smoothstep(radius - 0.015, radius + 0.015, dist);

    fragColor = color * mask * qt_Opacity;
}
