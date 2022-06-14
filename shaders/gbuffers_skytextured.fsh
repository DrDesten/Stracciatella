

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"

in vec2 coord;
flat in vec4 glcolor;

#ifdef HORIZON_CLIP
uniform vec3 up;
in vec3 viewPos;
#endif

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 FragOut0;
void main() {
	vec4 color = getAlbedo(coord) * glcolor;

	#ifdef HORIZON_CLIP
		color.rgb *= saturate(dot(normalize(viewPos), up) * HORIZON_CLIP_TRANSITION - (HORIZON_CLIP_HEIGHT * HORIZON_CLIP_TRANSITION));
	#endif

    #if DITHERING >= 2
		color.rgb += ditherColor(gl_FragCoord.xy);
	#endif

	FragOut0 = color; //gcolor
}