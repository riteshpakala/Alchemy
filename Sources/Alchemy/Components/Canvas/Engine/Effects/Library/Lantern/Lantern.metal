//
//  Lantern.metal
//  Alchemy
//
//  Created by Ritesh Pakala Rao on 10/31/26.
//

#include <metal_stdlib>

using namespace metal;

// Simple 2D Perlin-like noise using fractional part and smoothstep
static float perlin2D(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = mix(mix(sin(i.x + i.y * 43.0) * 43.0, sin((i.x + 1.0) + i.y * 43.0) * 43.0, f.x),
                  mix(sin(i.x + (i.y + 1.0) * 43.0) * 43.0, sin((i.x + 1.0) + (i.y + 1.0) * 43.0) * 43.0, f.x),
                  f.y);
    return fract(a / 43.0);
}

// Improved Perlin with gradient vectors for directional flow
static float2 perlinGrad2D(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float hash = sin(i.x + i.y * 43.0) * 43.0;
    float angle = fract(hash / 43.0) * 6.2831853;
    return float2(cos(angle), sin(angle));
}

// Gradient-weighted directional flow for watercolor stroke feel
static float directionalFlow(float2 uv, float2 center, float scale, float time) {
    float2 toCenter = uv - center;
    float dist = length(toCenter);
    float angle = atan2(toCenter.y, toCenter.x);
    
    // Flow direction rotates with time, creating organic stroke paths
    float flowAngle = angle + time * 0.3 + perlin2D(uv * scale) * 1.5;
    float2 flowDir = float2(cos(flowAngle), sin(flowAngle));
    
    // Gradient weight: stronger along the flow direction, weaker perpendicular
    float gradientWeight = 0.5 + 0.5 * dot(flowDir, float2(1.0, 0.0));
    return gradientWeight * smoothstep(scale * 0.8, scale * 0.3, dist);
}

// HSV to RGB conversion
static float3 hsvToRgb(float3 c) {
    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.w);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// Voronoi-style cell noise for organic blot shapes
static float voronoi2D(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    
    float d = 1e10;
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            float2 g = float2(x, y) + perlin2D(i + float2(x, y));
            float2 r = g - f;
            float dist = dot(r, r);
            if (dist < d) d = dist;
        }
    }
    return sqrt(d);
}

// Soft radial gradient with organic edge
float softRadial(float2 uv, float2 center, float radius, float softness) {
    float dist = length(uv - center);
    return smoothstep(radius + softness, radius - softness, dist);
}

// Paper texture grain for watercolor feel
static float paperGrain(float2 uv, float scale) {
    float grain = perlin2D(uv * scale) * 0.15;
    grain += perlin2D(uv * scale * 2.3 + 17.0) * 0.08;
    grain += perlin2D(uv * scale * 4.7 + 31.0) * 0.04;
    return grain;
}

// Edge feathering for watercolor bleed into paper
static float edgeFeather(float2 uv, float2 center, float radius, float time) {
    float dist = length(uv - center);
    float softEdge = smoothstep(radius + 0.12, radius - 0.08, dist);
    
    // Time-varying feather that simulates wet-on-wet bleeding
    float bleedFactor = perlin2D(float2(time * 0.25, uv.x * 3.0)) * 0.06;
    return smoothstep(radius + softEdge + bleedFactor, radius - softEdge - bleedFactor, dist);
}

kernel void lantern(
    texture2d<float, access::read> inputTexture,
    texture2d<float, access::write> outputTexture,
    device float* buffer [[buffer(0)]],
    constant float& time [[buffer(1)]],
    uint2 gid [[thread_position_in_grid]]
) {
    float2 uv = float2(gid) / float2(outputTexture.get_width(), outputTexture.get_height());
    
    // Voronoi cell pattern for blot centers with directional flow
    float cellNoise = voronoi2D(uv * 6.0 + float2(time * 0.1, time * 0.05));
    float blotMask = smoothstep(0.4, 0.1, cellNoise);
    
    // Gradient-weighted directional blots for watercolor stroke paths
    float2 flowCenter1 = float2(perlin2D(float2(time * 0.2, 0.3)) * 0.5 + 0.25,
                                 perlin2D(float2(0.1, time * 0.15)) * 0.5 + 0.3);
    float2 flowCenter2 = float2(perlin2D(float2(time * 0.15 + 1.7, 0.4)) * 0.5 + 0.6,
                                 perlin2D(float2(0.2, time * 0.1 + 2.3)) * 0.5 + 0.5);
    float2 flowCenter3 = float2(perlin2D(float2(time * 0.25 + 3.1, 0.2)) * 0.5 + 0.35,
                                 perlin2D(float2(0.3, time * 0.18 + 4.1)) * 0.5 + 0.7);
    
    float blot1 = directionalFlow(uv, flowCenter1, 0.25 + perlin2D(float2(time, 0.5)) * 0.1, time * 0.4);
    float blot2 = directionalFlow(uv, flowCenter2, 0.2 + perlin2D(float2(time * 0.7, 0.8)) * 0.12, time * 0.35 + 1.7);
    float blot3 = directionalFlow(uv, flowCenter3, 0.18 + perlin2D(float2(time * 0.5, 0.6)) * 0.08, time * 0.3 + 3.1);
    
    // Combine blots with gradient-weighted additive blending
    float combinedBlot = min(1.0, blot1 + blot2 * 0.7 + blot3 * 0.5);
    combinedBlot *= blotMask;
    
    // Gradient-weighted watercolor bleed: directional spread along flow paths
    float bleedStrength = perlin2D(float2(uv.x * 4.0 + time * 0.3, uv.y * 4.0 + time * 0.2)) * 0.15;
    
    // Directional bleed offset based on gradient flow
    float flowAngle = atan2(perlin2D(uv * 3.0 + time * 0.2) - 0.5, perlin2D(uv * 3.0 + 1.7) - 0.5);
    float2 bleedDir = float2(cos(flowAngle), sin(flowAngle));
    float2 bleedOffset = bleedDir * bleedStrength * (0.5 + 0.5 * combinedBlot);
    
    float2 sampleUV = uv + bleedOffset;
    sampleUV = clamp(sampleUV, float2(0.0), float2(1.0));
    
    float4 color = inputTexture.read(uint2(sampleUV.x * outputTexture.get_width(),
                                           sampleUV.y * outputTexture.get_height()));
    
    // Explicitly clear regions with low input alpha or no blot to transparent black
    // This ensures MTKView's clearColor is respected and black background regions are cleared
    if (color.a < 0.1 && combinedBlot < 0.2) {
        outputTexture.write(float4(0.0, 0.0, 0.0, 0.0), gid);
        return;
    }
    
    // Watercolor palette: warm amber/gold lantern tones with subtle rainbow hints
    float baseHue = 0.1 + perlin2D(float2(time * 0.05, 0.7)) * 0.1;
    float3 lanternBase = hsvToRgb(float3(baseHue, 0.5, 0.95));
    
    // Rainbow undertone that shifts with time and position
    float rainbowHue = fract(time * 0.02 + uv.x * 0.3 + uv.y * 0.2);
    float3 rainbowTint = hsvToRgb(float3(rainbowHue, 0.35, 0.85));
    
    // Gradient-weighted blending: stronger at blot centers, feathered at edges
    float gradientBlend = combinedBlot * buffer[0];
    float3 blendedRGB = mix(color.rgb, lanternBase, gradientBlend * 0.7);
    blendedRGB = mix(blendedRGB, rainbowTint, gradientBlend * 0.25);
    
    // Edge glow with directional feathering for watercolor bleed into paper
    float edgeGlow = smoothstep(0.35, 0.15, cellNoise) * combinedBlot * 0.4;
    blendedRGB += lanternBase * edgeGlow * buffer[0] * 0.5;
    
    // Paper texture grain overlay for authentic watercolor feel
    float grain = paperGrain(uv, 8.0);
    blendedRGB += lanternBase * grain * gradientBlend * 0.15;
    
    // Gradient-weighted transparency: darker where blots overlap, feathered at edges
    float alpha = color.a * (1.0 - combinedBlot * 0.3) + combinedBlot * 0.85;
    alpha = mix(alpha, 1.0, combinedBlot * buffer[0] * 0.2);
    
    float4 finalColor = float4(blendedRGB, alpha);
    
    outputTexture.write(finalColor, gid);
}
