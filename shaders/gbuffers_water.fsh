#version 120

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"

uniform vec3  fogColor;
uniform int   isEyeInWater;
uniform float far;

#include "/lib/fog.glsl"
#include "/lib/sky.glsl"

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

/* DRAWBUFFERS:0 */
void main() {
	vec4 color = getAlbedo(coord);
	color.rgb *= glcolor.rgb * glcolor.a;
	color.rgb *= getLightmap(lmcoord);


	#ifdef FOG

		float fog;
		if (isEyeInWater == 0) {

			fog  = fogFactor(viewPos, far, gbufferModelViewInverse);

			#if FOG_QUALITY == 1
			float cave = saturate(lmcoord.y * 4 - 0.25);
			color.rgb  = mix(color.rgb, mix(fogColor, getSkyColor(normalize(viewPos), sunDir, up, skyColor, fogColor, sunset), cave), fog);
			#else
			color.rgb = mix(color.rgb, fogColor, fog);
			#endif

		} else {

			fog  = fogExp(viewPos, isEyeInWater * FOG_UNDERWATER_DENSITY);

			#if FOG_QUALITY == 1
			color = mix(color, vec4(getSkyColor(normalize(viewPos), sunDir, up, skyColor, fogColor, sunset), 1), fog);
			#else
			color = mix(color, vec4(fogColor, 1), fog);
			#endif

		}

	#endif

	FD0 = color; //gcolor
}