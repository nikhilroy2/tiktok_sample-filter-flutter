#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;
uniform float uIntensity; // Pulse/Intensity from movement
uniform vec2 uHeadPos;    // Face location
uniform float uShowAura;  // 1.0 or 0.0

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;
    vec2 center = uHeadPos / uSize;
    
    // Dist from face center
    float d = distance(uv, center);
    
    // Heartbeat glow (4-6 sec cycle)
    float pulse = 0.5 + 0.5 * sin(uTime * 1.5 + uIntensity * 10.0);
    float glow = 0.05 / (d - 0.2 * pulse);
    glow *= uShowAura;

    // Color: Pinkish/Purple with Blue hints (like the photo)
    vec3 col = vec3(0.9, 0.4, 0.9) * glow;
    col += vec3(0.4, 0.4, 1.0) * (glow * 0.5);
    
    // Add some noise/sparkles
    float sparkles = fract(sin(dot(uv + uTime, vec2(12.9898, 78.233))) * 43758.5453);
    if (sparkles > 0.99 && glow > 0.1) col += vec3(1.0);

    fragColor = vec4(col, clamp(glow, 0.0, 1.0));
}
