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


varying vec2 coord;
varying vec4 glcolor;
varying vec3 viewPos;


/* DRAWBUFFERS:0 */
void main() {
	vec4 color = getAlbedo(coord) * glcolor;
	color.a    = fstep(0.1, color.a);

	#ifdef FOG

		float fog = fogFactor(viewPos * (1/1.414), far, gbufferModelViewInverse);

		#if FOG_QUALITY == 1

			#ifndef CUSTOM_SKY
				color.rgb = mix(color.rgb, getSkyColor(normalize(viewPos), sunDir, up, skyColor, fogColor, sunset), fog);
			#else
				color.rgb = mix(color.rgb, getSkyColor(normalize(viewPos), sunDir, up, skyColor, fogColor, sunset, rainStrength, daynight), fog);
			#endif

		#else

			#ifndef FOG_CUSTOM_COLOR
				color.rgb = mix(color.rgb, fogColor, fog);
			#else
				color.rgb = mix(color.rgb, getCustomFogColor(rainStrength, daynight), fog);
			#endif

		#endif


	#endif

	FD0 = color; //gcolor
}