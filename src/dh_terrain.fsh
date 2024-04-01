#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/core/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"
#include "/lib/transform.glsl"

uniform float far;

in vec2 lmcoord;
flat in vec4 glcolor;
in vec3 viewPos;

/* DRAWBUFFERS:01 */
layout(location = 0) out vec4 FragOut0;
layout(location = 1) out vec2 FragOut1;

void main() {
    vec3 playerPos = toPlayer(viewPos);
    vec3 worldPos  = toWorld(playerPos);

    // Discarding Logic

    float roundwh = floor(worldPos.y / 8) * 8;
    vec2  roundwp = floor(worldPos.xz / 16) * 16 + 8;
    vec2  roundcp = floor(cameraPosition.xz / 16) * 16 + 8;

    vec2  floorwp = floor(worldPos.xz / 16) * 16;
    vec2  ceilwp  = ceil(worldPos.xz / 16) * 16;
    float mindist = sqrt(min(
        min(sqmag(vec2(floorwp.x, floorwp.y) - cameraPosition.xz),
            sqmag(vec2(floorwp.x, ceilwp.y)  - cameraPosition.xz)),
        min(sqmag(vec2(ceilwp.x,  floorwp.y) - cameraPosition.xz),
            sqmag(vec2(ceilwp.x,  ceilwp.y)  - cameraPosition.xz))
    ));
    
    bool chunkdiscardable  = length(roundcp - roundwp) - 8 < far;
    bool distdiscardable   = mindist < far;
    bool heightdiscardable = abs(roundwh - cameraPosition.y) - 8 < far;

    if ( chunkdiscardable && distdiscardable && heightdiscardable ) {
        discard;
    }

    

    FragOut0 = glcolor;
	FragOut1 = encodeLightmapData(vec4(lmcoord, 1,0));

    /* if ( chunkdiscardable ) {
        FragOut0 = vec4(0,1,0,1);
    }
    if ( distdiscardable ) {
        FragOut0 = vec4(0,0,1,1);
    } */
}