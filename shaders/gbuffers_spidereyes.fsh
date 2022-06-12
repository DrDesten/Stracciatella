

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"

in vec2 coord;
flat in vec4 glcolor;

/* DRAWBUFFERS:01 */
layout(location = 0) out vec4 out0;
layout(location = 1) out vec4 out1;
void main() {
	vec4 color = getAlbedo(coord) * glcolor;

	out0 = color; //gcolor
	out1 = vec4(1,1,0,1);
}