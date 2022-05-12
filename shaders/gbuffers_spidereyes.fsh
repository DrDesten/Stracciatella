

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"

in vec2 coord;
in vec4 glcolor;

void main() {
	vec4 color = getAlbedo(coord) * glcolor;

/* DRAWBUFFERS:0 */
	gl_FragData[0] = color; //gcolor
}