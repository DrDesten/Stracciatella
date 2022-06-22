#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"

#ifdef HAND_WATER
	#include "/lib/lightmap.glsl"
#endif

#ifdef CUSTOM_LIGHTMAP
	uniform float customLightmapBlend;
#endif

flat in vec2 lmcoord;
in vec2 coord;
flat in vec4 glcolor;

/* DRAWBUFFERS:01 */
layout(location = 0) out vec4 FragOut0;
layout(location = 1) out uint FragOut1;
void main() {
	vec4 color = getAlbedo(coord) * glcolor;

	#ifdef HAND_WATER

	#ifndef CUSTOM_LIGHTMAP
	color.rgb *= getLightmap(lmcoord) * glcolor.a;
	#else
	color.rgb *= getCustomLightmap(lmcoord, customLightmapBlend, glcolor.a);
	#endif

	#endif

    #if DITHERING >= 2
		color.rgb += ditherColor(gl_FragCoord.xy);
	#endif

	FragOut0 = color; //gcolor
    if (FragOut0.a < 0.1) discard;
	FragOut1 = vec4toUI(vec4(lmcoord, 1,0));
}