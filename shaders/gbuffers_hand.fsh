#version 120

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"

#ifdef CUSTOM_LIGHTMAP
	uniform float customLightmapBlend;
#endif

varying vec2 lmcoord;
varying vec2 coord;
varying vec4 glcolor;

/* DRAWBUFFERS:0 */
void main() {
	vec4 color = getAlbedo(coord) * glcolor;

	#ifndef CUSTOM_LIGHTMAP
	color.rgb *= getLightmap(lmcoord);
	#else
	color.rgb *= getCustomLightmap(lmcoord, customLightmapBlend, 1);
	#endif

	FD0 = color; //gcolor
}