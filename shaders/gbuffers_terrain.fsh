#version 130

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"

uniform vec3  fogColor;
uniform int   isEyeInWater;
uniform float far;

#include "/lib/fog_sky.glsl"

#ifdef FOG

uniform mat4 gbufferModelViewInverse;

#if FOG_QUALITY == 1
uniform vec3  sunDir;
uniform vec3  up;
uniform float sunset;
uniform vec3  skyColor;
#endif

#endif

varying vec2 lmcoord;
varying vec2 coord;
varying vec4 glcolor;
varying vec3 viewPos;

#ifdef RAIN_PUDDLES
uniform sampler2D colortex7;
uniform float     frameTimeCounter;
uniform float     isRainSmooth;
varying float     puddle;
varying vec2      blockCoords;
#endif

/* DRAWBUFFERS:0 */
void main() {
	vec4 color = getAlbedo(coord);
	color.rgb *= glcolor.rgb * glcolor.a;
	color.rgb *= getLightmap(lmcoord);


	#ifdef RAIN_PUDDLES

		if (isRainSmooth > 1e-10) {

			vec2 waterTextureSize = vec2(textureSize(colortex7, 0));
			vec2 waterCoords      = vec2(blockCoords.x, blockCoords.y * (waterTextureSize.x / waterTextureSize.y));
			waterCoords.y        += (waterTextureSize.x / waterTextureSize.y) * round(frameTimeCounter * 2);
			vec4 waterTexture     = texture2D(colortex7, waterCoords);
			waterTexture.rgb      = waterTexture.rgb * vec3(0.2, 0.27, 0.7);

			color.rgb = mix(color.rgb, waterTexture.rgb, puddle * waterTexture.a);

		}

	#endif


	#ifdef FOG

		float fog = fogFactor(viewPos, far, gbufferModelViewInverse);

		#if FOG_QUALITY == 1
		float cave = saturate(lmcoord.y * 4 - 0.25);
		color.rgb  = mix(color.rgb, mix(fogColor, getFogSkyColor(normalize(viewPos), sunDir, up, skyColor, fogColor, sunset, isEyeInWater), cave), fog);
		#else
		color.rgb = mix(color.rgb, fogColor, fog);
		#endif


	#endif



	FD0 = color; //gcolor
}