//
//  Whirl.metal
//  Alchemy
//
//  Created by Ritesh Pakala Rao on 10/31/26.
//

#include <metal_stdlib>

using namespace metal;

kernel void whirl(
    texture2d<float, access::read> inputTexture,
    texture2d<float, access::write> outputTexture,
    device float* buffer [[buffer(0)]],
    uint gid [[thread_index_in_threadgroup]]
) {
    if (gid >= outputTexture.get_width() * outputTexture.get_height()) {
        return;
    }
    
    uint x = gid % outputTexture.get_width();
    uint y = gid / outputTexture.get_width();
    
    float4 color = inputTexture.read(uint2(x, y));
    outputTexture.write(color, uint2(x, y));
}
