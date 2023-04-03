#if ! defined INCLUDE_GBUFFERS_SKYTEXTURED_FSH
#define INCLUDE_GBUFFERS_SKYTEXTURED_FSH

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"

in vec2 coord;
in float isAurora;

#ifdef HORIZON_CLIP
#if ! defined INCLUDE_UNIFORM_vec3_up
#define INCLUDE_UNIFORM_vec3_up
uniform vec3 up; 
#endif
in vec3 viewPos;
#endif

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 FragOut0;
void main() {
	vec4 color = getAlbedo(coord);
/* 
	#ifdef HORIZON_CLIP
		color.rgb *= saturate(dot(normalize(viewPos), up) * HORIZON_CLIP_TRANSITION - (HORIZON_CLIP_HEIGHT * HORIZON_CLIP_TRANSITION));
	#endif
 */
    #if DITHERING >= 2
		color.rgb += ditherColor(gl_FragCoord.xy);
	#endif

	FragOut0 = color;
    //if (isAurora != 0) FragOut0.rgb = vec3(coord,0) / 2;
}

#endif