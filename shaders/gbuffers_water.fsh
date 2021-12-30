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

	#if FOG_QUALITY == 1

		uniform vec3  sunDir;
		uniform vec3  up;
		uniform float sunset;
		uniform vec3  skyColor;
		
		#ifdef CUSTOM_SKY
		uniform float daynight;
		uniform float rainStrength;
		#endif

	#endif

#endif

varying vec2 lmcoord;
varying vec2 coord;
varying vec4 glcolor;
varying vec3 viewPos;

/* DRAWBUFFERS:0 */
void main() {
	vec4 color = getAlbedo(coord);
	color.rgb *= glcolor.rgb * glcolor.a;
	color.rgb *= getLightmap(lmcoord);


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
		color.rgb = mix(color.rgb, fogColor, fog);
		#endif

	#endif

	FD0 = color; //gcolor
}