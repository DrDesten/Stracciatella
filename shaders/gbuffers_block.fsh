

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"

#ifdef CUSTOM_LIGHTMAP
	uniform float customLightmapBlend;
#endif

in vec2 lmcoord;
in vec2 coord;
flat in vec4 glcolor;
in vec3 viewPos;

/* DRAWBUFFERS:01 */
layout(location = 0) out vec4 out0;
layout(location = 1) out uint out1;
void main() {
	vec4 color = getAlbedo(coord);
	color.rgb *= glcolor.rgb;

    #if DITHERING >= 2
		color.rgb += ditherColor(gl_FragCoord.xy);
	#endif
	out0 = color; //gcolor
	out1 = encodeLMCoordBuffer(vec4(lmcoord, 1,0));
}