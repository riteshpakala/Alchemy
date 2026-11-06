//
//  Fill.metal
//  Alchemy
//
//  Created by Ritesh Pakala Rao on 11/6/26.
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
    outputTexture.write(color, gid);
}
