#version 120

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"

varying vec2 lmcoord;
varying vec2 coord;
varying vec4 glcolor;

/* DRAWBUFFERS:0 */
void main() {
	vec4 color = getAlbedo(coord) * glcolor;
	color.rgb *= getLightmap(lmcoord);

	FD0 = color; //gcolor
}