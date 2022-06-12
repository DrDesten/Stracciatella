

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"

in vec2 coord;
flat in vec4 glcolor;

/* DRAWBUFFERS:01 */
layout(location = 0) out vec4 out0;
layout(location = 1) out uint out1;
void main() {
	vec4 color = getAlbedo(coord) * glcolor;

    #if DITHERING >= 2
		color.rgb += ditherColor(gl_FragCoord.xy);
	#endif
	out0 = color; //gcolor
	out1 = encodeLMCoordBuffer(vec4(1));
}