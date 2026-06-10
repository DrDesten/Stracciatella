
const vec2 workGroupsRender = vec2(0.25, 0.25);

#include "/core/core.glsl"

uniform sampler2D colortex5;

layout (local_size_x = 8, local_size_y = 8) in;
layout (rgba8_snorm) uniform image2D colorimg6;

shared vec4 sharedHits[8][8];

void main() {
    ivec2 baseCoord = ivec2(gl_GlobalInvocationID.xy) * 4;

    // Sample and reduce
    vec4 localHits = vec4(0);
    for (int x = 0; x < 4; x++)
    for (int y = 0; y < 4; y++) {
        vec3 texel = texelFetch(colortex5, baseCoord + ivec2(x,y), 0).rgb;
        if (texel != vec3(0)) {
            vec3 color = rgb2oklab(texel);
            localHits += vec4(color, 1);
        }
    }

    // Store hit
    sharedHits[gl_LocalInvocationID.x][gl_LocalInvocationID.y] = localHits;

    // synchronize
    barrier();

    if (gl_LocalInvocationID.xy != uvec2(0)) return;

    // Reduce shared
    vec4 globalHit = vec4(0);
    for (int x = 0; x < 8; x++)
    for (int y = 0; y < 8; y++) {
        vec4 hit = sharedHits[x][y];
        globalHit += hit;
    }

    if (globalHit.a > 0) {
        globalHit.rgb = globalHit.rgb / globalHit.a;
        globalHit.a  /= 32; // this is *intentionally* 32, and not 32²
    }

    // Store result
    ivec2 storeCoord = ivec2(gl_GlobalInvocationID.xy) / 8;
    imageStore(colorimg6, storeCoord, globalHit);
}