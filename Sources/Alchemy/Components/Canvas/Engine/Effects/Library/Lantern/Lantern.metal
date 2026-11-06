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

// HSV to RGB conversion
static float3 hsvToRgb(float3 c) {
    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.w);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// Voronoi-style cell noise for organic blot shapes
float voronoi2D(float2 p) {
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

kernel void lantern(
    texture2d<float, access::read> inputTexture,
    texture2d<float, access::write> outputTexture,
    device float* buffer [[buffer(0)]],
    constant float& time [[buffer(1)]],
    uint2 gid [[thread_position_in_grid]]
) {
    float2 uv = float2(gid) / float2(outputTexture.get_width(), outputTexture.get_height());
    
    // Voronoi cell pattern for blot centers
    float cellNoise = voronoi2D(uv * 6.0 + float2(time * 0.1, time * 0.05));
    float blotMask = smoothstep(0.4, 0.1, cellNoise);
    
    // Multiple overlapping blot layers with different scales
    float blot1 = softRadial(uv, float2(perlin2D(float2(time * 0.2, 0.3)) * 0.5 + 0.25, 
                                          perlin2D(float2(0.1, time * 0.15)) * 0.5 + 0.3),
                              0.25 + perlin2D(float2(time, 0.5)) * 0.1,
                              0.15);
    float blot2 = softRadial(uv, float2(perlin2D(float2(time * 0.15 + 1.7, 0.4)) * 0.5 + 0.6,
                                          perlin2D(float2(0.2, time * 0.1 + 2.3)) * 0.5 + 0.5),
                              0.2 + perlin2D(float2(time * 0.7, 0.8)) * 0.12,
                              0.18);
    float blot3 = softRadial(uv, float2(perlin2D(float2(time * 0.25 + 3.1, 0.2)) * 0.5 + 0.35,
                                          perlin2D(float2(0.3, time * 0.18 + 4.1)) * 0.5 + 0.7),
                              0.18 + perlin2D(float2(time * 0.5, 0.6)) * 0.08,
                              0.12);
    
    // Combine blots with additive blending and clamp
    float combinedBlot = min(1.0, blot1 + blot2 * 0.7 + blot3 * 0.5);
    combinedBlot *= blotMask;
    
    // Watercolor bleed effect: blur-like spread based on time
    float bleedStrength = perlin2D(float2(uv.x * 4.0 + time * 0.3, uv.y * 4.0 + time * 0.2)) * 0.15;
    
    // Sample original color with slight offset for bleed
    float2 bleedOffset = float2(
        perlin2D(float2(uv.x * 8.0, uv.y * 8.0) + time * 0.1) * bleedStrength,
        perlin2D(float2(uv.x * 8.0 + 100.0, uv.y * 8.0) + time * 0.1) * bleedStrength
    );
    float2 sampleUV = uv + bleedOffset;
    sampleUV = clamp(sampleUV, float2(0.0), float2(1.0));
    
    float4 color = inputTexture.read(uint2(sampleUV.x * outputTexture.get_width(), 
                                           sampleUV.y * outputTexture.get_height()));
    
    // Watercolor palette: warm amber/gold lantern tones with subtle rainbow hints
    float baseHue = 0.1 + perlin2D(float2(time * 0.05, 0.7)) * 0.1; // Amber-gold range
    float3 lanternBase = hsvToRgb(float3(baseHue, 0.5, 0.95));
    
    // Rainbow undertone that shifts with time
    float rainbowHue = fract(time * 0.02 + uv.x * 0.3 + uv.y * 0.2);
    float3 rainbowTint = hsvToRgb(float3(rainbowHue, 0.35, 0.85));
    
    // Blend base color with lantern glow and rainbow undertone
    float glowIntensity = combinedBlot * buffer[0];
    float3 blendedRGB = mix(color.rgb, lanternBase, glowIntensity * 0.7);
    blendedRGB = mix(blendedRGB, rainbowTint, glowIntensity * 0.25);
    
    // Add soft outer glow around blot edges
    float edgeGlow = smoothstep(0.35, 0.15, cellNoise) * combinedBlot * 0.4;
    blendedRGB += lanternBase * edgeGlow * buffer[0] * 0.5;
    
    // Watercolor transparency: darker where blots overlap
    float alpha = color.a * (1.0 - combinedBlot * 0.3) + combinedBlot * 0.85;
    
    float4 finalColor = float4(blendedRGB, alpha);
    
    outputTexture.write(finalColor, gid);
}
