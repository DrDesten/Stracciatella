#if ! defined INCLUDE_GBUFFERS_ARMOR_GLINT_FSH
#define INCLUDE_GBUFFERS_ARMOR_GLINT_FSH

#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/core/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"
#if ! defined INCLUDE_UNIFORM_sampler2D_lightmap
#define INCLUDE_UNIFORM_sampler2D_lightmap
uniform sampler2D lightmap; 
#endif
in vec2 lmcoord;
in vec2 coord;
flat in vec4 glcolor;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 FragOut0;

void main() {
	vec4 color = getAlbedo(coord) * glcolor;
	color.rgb *= texture(lightmap, lmcoord).rgb;

	#if DITHERING >= 2
		color.rgb += ditherColor(gl_FragCoord.xy);
	#endif

	FragOut0 = color; //gcolor
    if (FragOut0.a < 0.1) discard;
}


#endif