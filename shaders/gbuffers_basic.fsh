#if ! defined INCLUDE_GBUFFERS_BASIC_FSH
#define INCLUDE_GBUFFERS_BASIC_FSH

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"
#if ! defined INCLUDE_UNIFORM_sampler2D_lightmap
#define INCLUDE_UNIFORM_sampler2D_lightmap
uniform sampler2D lightmap; 
#endif
in vec2 lmcoord;
flat in vec4 glcolor;

#if BLOCK_OUTLINE_STYLE == 2
#if ! defined INCLUDE_UNIFORM_float_frameTimeCounter
#define INCLUDE_UNIFORM_float_frameTimeCounter
uniform float frameTimeCounter; 
#endif
#endif

/* DRAWBUFFERS:01 */
layout(location = 0) out vec4 FragOut0;
layout(location = 1) out vec4 FragOut1; // Even if only two channels are used, I need to set alpha in order for blending to not fuck up
void main() {
	vec4 color = glcolor;
	color.rgb *= texture(lightmap, lmcoord).rgb;

	#if MC_VERSION < 11700 || defined IS_IRIS

		#if BLOCK_OUTLINE_STYLE != 0
		if (color.a < 0.5) {

			#if BLOCK_OUTLINE_STYLE == 1

			color.rgb = vec3(1); // White

			#elif BLOCK_OUTLINE_STYLE == 2

			//color.rgb = (sin(frameTimeCounter * vec3(-0.5, 1, 0.25)) * 0.5 + 0.6); // Rainbow
			color.rgb = hsv2rgb(vec3(fract(frameTimeCounter * 10), 1, 1)); // Rainbow

			#elif BLOCK_OUTLINE_STYLE == 3

			color.rgb = vec3(BLOCK_OUTLINE_COLOR_R, BLOCK_OUTLINE_COLOR_G, BLOCK_OUTLINE_COLOR_B); // Custom Color

			#endif

		}
		#endif

		#ifdef BLOCK_OUTLINE_SOLID
		color.a = fstep(0.1, color.a);
		#endif

	#endif

    #if DITHERING >= 2
		color.rgb += ditherColor(gl_FragCoord.xy);
	#endif

	FragOut0 = color; //gcolor
    if (FragOut0.a < 0.1) discard;
	FragOut1 = vec4( encodeLightmapData(vec4(lmcoord, 1,0)), 1,1 );
}

#endif