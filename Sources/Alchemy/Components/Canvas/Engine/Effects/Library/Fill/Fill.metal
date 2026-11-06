//
//  Fill.metal
//  Alchemy
//
//  Created by Ritesh Pakala Rao on 10/31/26.
//

#include <metal_stdlib>

using namespace metal;

/// Fills a texture with a solid RGBA color.
/// Uses outputTexture dimensions directly instead of param buffers,
/// allowing the shader to work with any output texture size.
kernel void solidColorFill(
    texture2d<float, access::read> inputTexture [[texture(0)]],
    texture2d<float, access::write> outputTexture [[texture(1)]],
    constant float4& color [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    // Bounds check against output texture dimensions
//    if (gid >= outputTexture.get_width() * outputTexture.get_height()) {
//        return;
//    }
    
//    uint x = gid % outputTexture.get_width();
//    uint y = gid / outputTexture.get_width();
    
//    // Compute UV coordinates based on output texture size
//    float2 uv = float2(x, y) / float2(outputTexture.get_width(), outputTexture.get_height());
//    
//    // Sample from input texture using the same UV coordinates
//    // This handles cases where input and output have different dimensions
//    uint2 samplePos = uint2(x, y);
//    
//    // Clamp to input texture bounds
//    samplePos.x = min(samplePos.x, inputTexture.get_width() - 1);
//    samplePos.y = min(samplePos.y, inputTexture.get_height() - 1);
//    
//    float4 sampledColor = inputTexture.read(samplePos);
//    
//    // Blend the solid color with the sampled color
//    // If input is fully transparent, use solid color; otherwise blend
//    float alphaMix = color.a * 0.3 + sampledColor.a * 0.7;
//    float3 blendedRGB = mix(sampledColor.rgb, color.rgb, color.a);
//    
//    float4 finalColor = float4(blendedRGB, alphaMix);
//    outputTexture.write(finalColor, uint2(x, y));
    outputTexture.write(float4(0.0, 0.0, 1.0, 1.0), gid);
}
