#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"


#ifdef HAND_WATER
	uniform float frameTimeCounter;
	#include "/lib/lightmap.glsl"
#endif

uniform float customLightmapBlend;

flat in vec2 lmcoord;
in vec2 coord;
flat in vec4 glcolor;

/* DRAWBUFFERS:01 */
layout(location = 0) out vec4 FragOut0;
layout(location = 1) out vec4 FragOut1; // Even if only two channels are used, I need to set alpha in order for blending to not fuck up
void main() {
	vec4 color = getAlbedo(coord) * glcolor;

	#ifdef HAND_WATER

	color.rgb *= getCustomLightmap(vec3(lmcoord, glcolor.a), customLightmapBlend);

	#endif

    #if DITHERING >= 2
		color.rgb += ditherColor(gl_FragCoord.xy);
	#endif

	FragOut0 = color; //gcolor
    if (FragOut0.a < 0.1) discard;
	FragOut1 = vec4( encodeLightmapData(vec4(lmcoord, 1,0)), 1.0, 1.0 );
}