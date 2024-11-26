#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/core/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"
#include "/core/transform.glsl"
#include "/lib/dh.glsl"
#include "/lib/time.glsl"

#include "/core/dh/uniforms.glsl"
#include "/core/dh/transform.glsl"

uniform vec2 screenSize;
uniform vec2 screenSizeInverse;
#include "/lib/lightmap.glsl"

uniform sampler2D depthtex0;
uniform float near;
uniform float far;

uniform sampler2D colortex4;
uniform float customLightmapBlend;

#if FOG != 0
uniform ivec2 eyeBrightnessSmooth;
#include "/lib/sky.glsl"
#endif

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
    
#ifdef DH_TRANSPARENT_DISCARD
    float borderTolerance = (materialId == DH_BLOCK_WATER ? 0 : 1e-5) + DH_TRANSPARENT_DISCARD_TOLERANCE;
    if ( discardDH(worldPos, borderTolerance) ) {
        discard;
    }
#else
    float fade = smoothstep( dhNearPlane, min(dhNearPlane * 2 + 32, far * 0.5), -viewPos.z ) - sq(Bayer8(gl_FragCoord.xy));
    if ( fade < 0 ) {
        discard;
    }
#endif

    float depth         = texelFetch(depthtex0, ivec2(gl_FragCoord.xy), 0).x;
    float dhDepth       = gl_FragCoord.z;
    vec3  dhScreenPos   = vec3(gl_FragCoord.xy * screenSizeInverse, dhDepth);
    vec3  dhViewPos     = screenToViewDH(dhScreenPos);
    float dhMappedDepth = backToScreen(dhViewPos).z;

    if (depth < 1 && depth < dhMappedDepth) {
        discard;
    }
    
    vec4 color = glcolor;

    if (materialId == DH_BLOCK_WATER) {
        vec2  waterTextureSize   = vec2(textureSize(colortex4, 0));
        float waterTextureAspect = waterTextureSize.x / waterTextureSize.y;
        vec2  blockCoords        = fract(worldPos.xz);
        vec2  waterCoords        = vec2(blockCoords.x, blockCoords.y * waterTextureAspect);
        waterCoords.y           += waterTextureAspect * floor(time * 10);

        float texelDensity = max(
            length(dFdx(worldPos.xz)),
            length(dFdy(worldPos.xz))
        ) * minc(waterTextureSize);
        float textureBlend = saturate(texelDensity * 0.5 - 1);
        vec4  waterTexture = texture(colortex4, waterCoords);
        vec4  waterColor   = waterTexture * vec4(glcolor.rgb * 1.5, 1);

        color = mix(waterColor, color, textureBlend);
    }

	color.rgb *= getCustomLightmap(vec3(lmcoord, 1), customLightmapBlend);

	#if FOG != 0

		vec3 viewDir = normalize(viewPos);
        vec3 playerDir;
        #if defined END 
        playerDir = normalize(playerPos);
        #endif

		float fog = fogFactorTerrain(playerPos);
        
        #if FOG_ADVANCED
        float fa = fogFactorAdvanced(viewDir, playerPos);
        fog      = max(fog, fa);
        #endif

		#ifdef OVERWORLD
			float cave = max( saturate(eyeBrightnessSmooth.y * (4./240.) - 0.25), saturate(lmcoord.y * 1.5 - 0.25) );
		    cave       = saturate( cave + float(cameraPosition.y > 512) );
		#else
			float cave = 1;
		#endif

        color.rgb = mix(color.rgb, mix(fogCaveColor, getFogSkyColor(viewDir, playerDir), cave), fog);

	#endif

    FragOut0 = color;
}