#version 120

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"

uniform vec4  entityColor;
uniform vec3  fogColor;
uniform int   isEyeInWater;
uniform float far;

#include "/lib/fog.glsl"
#include "/lib/sky.glsl"

#if FOG_QUALITY == 1
uniform vec3  sunDir;
uniform vec3  up;
uniform float sunset;
uniform vec3  skyColor;
#endif

varying vec2 lmcoord;
varying vec2 coord;
varying vec4 glcolor;
varying vec3 viewPos;

/* DRAWBUFFERS:0 */
void main() {
	vec4 color = getAlbedo(coord) * glcolor;
	color.rgb  = mix(color.rgb, entityColor.rgb, entityColor.a);
	color.rgb *= getLightmap(lmcoord);
	

	#ifdef FOG

		float fog = fogFactor(viewPos, far);
		
		#if FOG_QUALITY == 1
		color.rgb = mix(color.rgb, getSkyColor(normalize(viewPos), sunDir, up, skyColor, fogColor, sunset), fog);
		#else
		color.rgb = mix(color.rgb, fogColor, fog);
		#endif

	#endif

	FD0 = color; //gcolor
}