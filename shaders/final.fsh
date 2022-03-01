

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/composite_basics.glsl"

vec2 coord = gl_FragCoord.xy * screenSizeInverse * MC_RENDER_QUALITY;

/* DRAWBUFFERS:0 */
void main() {
	#ifdef BICUBIC_SAMPLING
	vec3 color = textureBicubic(colortex0, coord, screenSize, screenSizeInverse).rgb;
	#else
	vec3 color = getAlbedo(coord);
	#endif

	gl_FragColor = vec4(color, 1.0);
}