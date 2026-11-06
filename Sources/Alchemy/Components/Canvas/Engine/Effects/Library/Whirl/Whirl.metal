//
//  Whirl.metal
//  Alchemy
//
//  Created by Ritesh Pakala Rao on 10/31/26.
//

#include <metal_stdlib>

using namespace metal;

// Simple 2D Perlin-like noise using fractional part and smoothstep
float perlin2D(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = mix(mix(sin(i.x + i.y * 43.0) * 43.0, sin((i.x + 1.0) + i.y * 43.0) * 43.0, f.x),
                  mix(sin(i.x + (i.y + 1.0) * 43.0) * 43.0, sin((i.x + 1.0) + (i.y + 1.0) * 43.0) * 43.0, f.x),
                  f.y);
    return fract(a / 43.0);
}

// HSV to RGB conversion
float3 hsvToRgb(float3 c) {
    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.w);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

kernel void whirl(
    texture2d<float, access::read> inputTexture,
    texture2d<float, access::write> outputTexture,
    device float* buffer [[buffer(0)]],
    constant float& time [[buffer(1)]],
    uint gid [[thread_index_in_threadgroup]]
) {
    if (gid >= outputTexture.get_width() * outputTexture.get_height()) {
        return;
    }
    
    uint x = gid % outputTexture.get_width();
    uint y = gid / outputTexture.get_width();
    
    float2 uv = float2(x, y) / float2(outputTexture.get_width(), outputTexture.get_height());
    float2 center = float2(0.5, 0.5);
    
    // Polar coordinates from center
    float dx = uv.x - center.x;
    float dy = uv.y - center.y;
    float radius = length(float2(dx, dy));
    float angle = atan2(dy, dx);
    
    // Swirl displacement: angle shifts with radius + noise
    float noiseTerm = perlin2D(float2(radius * 8.0, angle * 4.0)) * 0.3;
    float swirlAngle = angle + radius * 6.0 + noiseTerm + time * 0.5;
    
    // Warped UV for sampling
    float warpedRadius = radius * (1.0 + perlin2D(float2(radius * 4.0, angle * 2.0)) * 0.2);
    float warpedX = center.x + warpedRadius * cos(swirlAngle);
    float warpedY = center.y + warpedRadius * sin(swirlAngle);
    float2 sampleUV = float2(warpedX, warpedY);
    
    // Clamp to texture bounds with wrap
    sampleUV = fract(sampleUV);
    
    float4 color = inputTexture.read(uint2(sampleUV.x * outputTexture.get_width(), sampleUV.y * outputTexture.get_height()));
    
    // Apply water-color rainbow overlay based on angle
    float hue = (swirlAngle / (2.0 * 3.14159) + 0.5) - floor((swirlAngle / (2.0 * 3.14159) + 0.5));
    float3 rgb = hsvToRgb(float3(hue, 0.6, 0.9));
    
    // Blend original color with rainbow overlay — sample modulates intensity
    float blend = radius < 0.3 ? 0.3 * buffer[0] : 0.6 * buffer[0];
    float4 finalColor = float4(mix(color.rgb, rgb, blend), color.a);
    
    outputTexture.write(finalColor, uint2(x, y));
}
