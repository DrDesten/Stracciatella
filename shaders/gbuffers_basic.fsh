#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"

in vec2 lmcoord;
flat in vec4 glcolor;

#if BLOCK_OUTLINE_STYLE == 2
uniform float frameTimeCounter;
#endif

/* DRAWBUFFERS:01 */
layout(location = 0) out vec4 FragOut0;
layout(location = 1) out uint FragOut1;
void main() {
	vec4 color = glcolor;
	color.rgb *= getLightmap(lmcoord);

	#if MC_VERSION < 11700

		#if BLOCK_OUTLINE_STYLE != 0
		if (color.a < 0.5) {

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

	#endif

    #if DITHERING >= 2
		color.rgb += ditherColor(gl_FragCoord.xy);
	#endif
	FragOut0 = color; //gcolor
    if (FragOut0.a < 0.1) discard;
	FragOut1 = vec4toUI(vec4(lmcoord, 1,0));
}