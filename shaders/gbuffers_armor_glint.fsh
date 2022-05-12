

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"

in vec2 lmcoord;
in vec2 coord;
in vec4 glcolor;

/* DRAWBUFFERS:0 */
void main() {
	vec4 color = getAlbedo(coord) * glcolor;
	color.rgb *= getLightmap(lmcoord);

	#if DITHERING >= 2
		color.rgb += ditherColor(gl_FragCoord.xy);
	#endif
	gl_FragData[0] = color; //gcolor
}