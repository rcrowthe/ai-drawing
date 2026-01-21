//
//  InkShaders.metal
//  AIDrawing
//
//  Metal shaders for low-latency ink rendering
//

#include <metal_stdlib>
using namespace metal;

// MARK: - Vertex Structures

struct VertexIn {
    float2 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
    float4 color [[attribute(2)]];
    float width [[attribute(3)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
    float4 color;
};

struct Uniforms {
    float4x4 projectionMatrix;
    float2 viewportSize;
};

// MARK: - Vertex Shader

vertex VertexOut ink_vertex_shader(
    VertexIn in [[stage_in]],
    constant Uniforms& uniforms [[buffer(1)]]
) {
    VertexOut out;

    // Transform position to normalized device coordinates
    float4 position = float4(in.position, 0.0, 1.0);
    out.position = uniforms.projectionMatrix * position;

    out.texCoord = in.texCoord;
    out.color = in.color;

    return out;
}

// MARK: - Fragment Shader

fragment float4 ink_fragment_shader(
    VertexOut in [[stage_in]]
) {
    // Basic rendering with alpha blending
    return in.color;
}

// MARK: - Fragment Shader with Antialiasing

fragment float4 ink_fragment_shader_aa(
    VertexOut in [[stage_in]]
) {
    // Antialias across stroke WIDTH (texCoord.x), not along stroke direction (texCoord.y)
    // texCoord.x goes from 0 (left edge) to 1 (right edge)
    float distFromCenter = abs(in.texCoord.x - 0.5);

    // Smooth antialiasing only at the very outer edges
    // Full opacity until distFromCenter = 0.48, then fade to transparent by 0.5
    float alpha = smoothstep(0.5, 0.48, distFromCenter);

    return float4(in.color.rgb, in.color.a * alpha);
}

// MARK: - Brush-Style Fragment Shader

fragment float4 ink_fragment_shader_brush(
    VertexOut in [[stage_in]]
) {
    // Circular brush with soft edges
    float2 center = float2(0.5, 0.5);
    float dist = distance(in.texCoord, center);

    // Smooth falloff from center to edge
    float alpha = 1.0 - smoothstep(0.3, 0.5, dist);

    return float4(in.color.rgb, in.color.a * alpha);
}

// MARK: - Predicted Stroke Fragment Shader (Ghost/Dashed)

fragment float4 ink_fragment_shader_predicted(
    VertexOut in [[stage_in]]
) {
    // Dashed pattern for predicted strokes
    float dashPattern = fract(in.texCoord.x * 10.0);
    float dashAlpha = step(0.5, dashPattern);

    // Lower opacity for predicted strokes
    float alpha = in.color.a * 0.3 * dashAlpha;

    return float4(in.color.rgb, alpha);
}
