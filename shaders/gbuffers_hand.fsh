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
layout(location = 0) out vec4 FragOut0;
layout(location = 1) out uint FragOut1;
layout(location = 2) out vec4 FragOut2;
void main() {
	vec4 color = getAlbedo(coord) * glcolor;

    #if DITHERING >= 2
		color.rgb += ditherColor(gl_FragCoord.xy);
	#endif

	FragOut0 = color; //gcolor
    if (FragOut0.a < 0.1) discard;
	FragOut1 = vec4toUI(vec4(lmcoord, 1,0));
	FragOut2 = vec4(0,0,0,1);
}