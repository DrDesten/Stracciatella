
const vec2 workGroupsRender = vec2(0.25, 0.25);

#include "/core/core.glsl"

uniform sampler2D colortex5;

layout (local_size_x = 4, local_size_y = 4) in;
layout (rgba8) uniform image2D colorimg6;

shared vec4 sharedHits[4][4];

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
    for (int x = 0; x < 4; x++)
    for (int y = 0; y < 4; y++) {
        globalHit += sharedHits[x][y];
    }

    if (globalHit.a > 0) {
        globalHit.rgb = oklab2rgb(globalHit.rgb / globalHit.a);
    }

    // Store result
    ivec2 storeCoord = ivec2(gl_GlobalInvocationID.xy) / 4;
    imageStore(colorimg6, storeCoord, globalHit);
}