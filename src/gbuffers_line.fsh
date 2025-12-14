#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/lib/gbuffers_basics.glsl"

uniform float frameTimeCounter;

#if BLOCK_OUTLINE_STYLE != 0
uniform int renderStage;
#endif

flat in vec4 glcolor;

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
    if (color.a < 0.1) discard;
	gl_FragData[1] = vec4(encodeLightmapData(vec4(1)), 1,1);
}