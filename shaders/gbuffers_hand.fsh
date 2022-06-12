#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"

#ifdef CUSTOM_LIGHTMAP
	uniform float customLightmapBlend;
#endif

flat in vec2 lmcoord;
in vec2 coord;
flat in vec4 glcolor;

/* DRAWBUFFERS:015 */
void main() {
	vec4 color = getAlbedo(coord) * glcolor;

    #if DITHERING >= 2
		color.rgb += ditherColor(gl_FragCoord.xy);
	#endif

	gl_FragData[0] = color; //gcolor
	gl_FragData[1] = uvec4(encodeLMCoordBuffer(vec4(lmcoord, 1,0)), 1,1,1);
	gl_FragData[2] = vec4(0,0,0,1);
}