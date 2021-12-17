#version 120

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"
uniform vec4 entityColor;

varying vec2 lmcoord;
varying vec2 coord;
varying vec4 glcolor;

void main() {
	vec4 color = getAlbedo(coord) * glcolor;
	color.rgb = mix(color.rgb, entityColor.rgb, entityColor.a);
	color.rgb *= getLightmap(lmcoord);

/* DRAWBUFFERS:0 */
	FD0 = color; //gcolor
}