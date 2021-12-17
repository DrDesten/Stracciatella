#version 120

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"

varying vec2 lmcoord;
varying vec2 coord;
varying vec4 glcolor;

void main() {
	vec4 color = getAlbedo(coord);
	color.rgb *= glcolor.rgb * glcolor.a;
	color.rgb *= getLightmap(lmcoord);

/* DRAWBUFFERS:0 */
	FD0 = color; //gcolor
}