

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"

uniform vec4  entityColor;

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
		uniform ivec2 eyeBrightnessSmooth;
		
	#endif

#endif

#ifdef CUSTOM_LIGHTMAP
	uniform float customLightmapBlend;
#endif

flat in vec2 lmcoord;
in vec2 coord;
flat in vec4 glcolor;
in vec3 viewPos;

/* DRAWBUFFERS:01 */
void main() {
	vec4 color = getAlbedo(coord) * glcolor;
	color.rgb  = mix(color.rgb, entityColor.rgb, entityColor.a);
	
	#ifndef CUSTOM_LIGHTMAP
	color.rgb *= getLightmap(lmcoord);
	#else
	color.rgb *= getCustomLightmap(lmcoord, customLightmapBlend, 1);
	#endif
	
    #if DITHERING >= 2
		color.rgb += ditherColor(gl_FragCoord.xy);
	#endif
	gl_FragData[0] = color; //gcolor
	gl_FragData[1] = vec4(lmcoord,0,1);
}