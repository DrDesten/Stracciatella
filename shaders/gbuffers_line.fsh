#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"

flat in vec4 glcolor;

#if BLOCK_OUTLINE_STYLE == 2
uniform float frameTimeCounter;
#endif

#if BLOCK_OUTLINE_STYLE != 0
uniform int renderStage;
#endif

/* DRAWBUFFERS:01 */
void main() {
	vec4 color = glcolor;

	#if BLOCK_OUTLINE_STYLE != 0
	if (renderStage == MC_RENDER_STAGE_OUTLINE) {

		#if BLOCK_OUTLINE_STYLE == 1

		color.rgb = vec3(1); // White

		#elif BLOCK_OUTLINE_STYLE == 2

		color.rgb = (sin(frameTimeCounter * vec3(-0.5, 1, 0.25)) * 0.5 + 0.6); // Rainbow

		#elif BLOCK_OUTLINE_STYLE == 3

		color.rgb = vec3(BLOCK_OUTLINE_COLOR_R, BLOCK_OUTLINE_COLOR_G, BLOCK_OUTLINE_COLOR_B); // Custom Color

		#endif

	}
	#endif

	#ifdef BLOCK_OUTLINE_SOLID
    color.a = fstep(0.1, color.a);
    #endif
    
    #if DITHERING >= 2
		color.rgb += ditherColor(gl_FragCoord.xy);
	#endif

	gl_FragData[0] = color; //gcolor
	gl_FragData[1] = vec4(1);
}