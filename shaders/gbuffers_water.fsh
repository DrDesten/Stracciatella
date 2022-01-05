#version 120

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"


#include "/lib/fog_sky.glsl"

#ifdef FOG

	uniform mat4  gbufferModelViewInverse;
	uniform vec3  fogColor;
	uniform int   isEyeInWater;
	uniform float far;

	#ifdef CUSTOM_SKY
		uniform float daynight;
		uniform float rainStrength;
	#endif

	#if FOG_QUALITY == 1

		uniform vec3  sunDir;
		uniform vec3  up;
		uniform float sunset;
		uniform vec3  skyColor;

	#endif

#endif

#ifdef CUSTOM_LIGHTMAP
	uniform float customLightmapBlend;
#endif

varying vec2 lmcoord;
varying vec2 coord;
varying vec4 glcolor;
varying vec3 viewPos;

/* DRAWBUFFERS:0 */
void main() {
	vec4 color = getAlbedo(coord);
	color.rgb *= glcolor.rgb * glcolor.a;
	
	#ifndef CUSTOM_LIGHTMAP
	color.rgb *= getLightmap(lmcoord) * glcolor.a;
	#else
	color.rgb *= getCustomLightmap(lmcoord, customLightmapBlend, glcolor.a);
	#endif


	#ifdef FOG

		float fog = fogFactor(viewPos, far, gbufferModelViewInverse);

		#if FOG_QUALITY == 1

			float cave = saturate(lmcoord.y * 4 - 0.25);

			#ifndef CUSTOM_SKY
				color.rgb  = mix(color.rgb, mix(fogColor, getFogSkyColor(normalize(viewPos), sunDir, up, skyColor, fogColor, sunset, isEyeInWater), cave), fog);
			#else
				color.rgb  = mix(color.rgb, mix(fogColor, getFogSkyColor(normalize(viewPos), sunDir, up, skyColor, fogColor, sunset, rainStrength, daynight, isEyeInWater), cave), fog);
			#endif

		#else

			#ifndef FOG_CUSTOM_COLOR
				color.rgb = mix(color.rgb, fogColor, fog);
			#else
				color.rgb = mix(color.rgb, getCustomFogColor(rainStrength, daynight), fog);
			#endif

		#endif

	#endif

    #if DITHERING >= 2
		color.rgb += ditherColor(gl_FragCoord.xy);
	#endif
	FD0 = color; //gcolor
}