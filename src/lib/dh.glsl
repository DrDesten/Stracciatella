#include "/core/core.glsl"
#include "/core/transform.glsl"

uniform float far;

bool discardDH(vec3 worldPos, float borderTolerance) {
    vec3  borderCorrection = vec3(lessThan(cameraPosition, worldPos)) * 2 * borderTolerance - borderTolerance;
    float roundwh = floor(worldPos.y / 8 + borderCorrection.y) * 8;
    vec2  roundwp = floor(worldPos.xz / 16 + borderCorrection.xz) * 16 + 8;
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

    return chunkdiscardable && distdiscardable && heightdiscardable;
}

bool discardDH(vec3 worldPos) {
    return discardDH(worldPos, 4./16);
}