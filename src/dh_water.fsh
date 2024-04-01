#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/core/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"
#include "/lib/transform.glsl"
#include "/core/dh/uniforms.glsl"

uniform float frameTimeCounter;
#include "/lib/lightmap.glsl"

uniform sampler2D depthtex0;
uniform float near;
uniform float far;

const bool colortex4MipmapEnabled = true;
uniform sampler2D colortex4;

uniform float customLightmapBlend;

uniform vec2 screenSize;

in vec2 lmcoord;
in vec2 coord;
flat in vec4 glcolor;
in vec3 viewPos;
flat in int materialId;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 FragOut0;
void main() {
    vec3 playerPos = toPlayer(viewPos);
    vec3 worldPos  = toWorld(playerPos);

    // Discarding Logic

    float roundwh = floor(worldPos.y / 8 - (1./16)) * 8;
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

    float depth    = texelFetch(depthtex0, ivec2(gl_FragCoord.xy), 0).x;
    float ldepth   = linearizeDepth(depth, near, far);
    float ldhdepth = linearizeDepth(gl_FragCoord.z, dhNearPlane, dhFarPlane);

    if (depth < 1 && ldepth < ldhdepth) {
        discard;
    }
    
    FragOut0 = glcolor;

    if (materialId == DH_BLOCK_WATER) {
        vec2  waterTextureSize   = vec2(textureSize(colortex4, 0));
        float waterTextureAspect = waterTextureSize.x / waterTextureSize.y;
        vec2  blockCoords        = fract(worldPos.xz);
        vec2  waterCoords        = vec2(blockCoords.x, blockCoords.y * waterTextureAspect);
        waterCoords.y           += waterTextureAspect * round(frameTimeCounter * 9);

        float texelDensity = max(
            length(dFdx(worldPos.xz)),
            length(dFdy(worldPos.xz))
        ) * minc(waterTextureSize);
        float textureBlend = saturate(texelDensity * 0.5 - 1);
        vec4  waterTexture = texture(colortex4, waterCoords);
        vec4  waterColor   = waterTexture * vec4(glcolor.rgb * 1.5, 1);

        FragOut0 = mix(waterColor, FragOut0, textureBlend);
    }

	FragOut0.rgb *= getCustomLightmap(vec3(lmcoord, 1), customLightmapBlend);
}