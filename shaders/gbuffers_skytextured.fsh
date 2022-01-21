

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"

varying vec2 coord;
varying vec4 glcolor;

#ifdef HORIZON_CLIP
uniform vec3 up;
varying vec3 viewPos;
#endif

/* DRAWBUFFERS:0 */
void main() {
	vec4 color = getAlbedo(coord) * glcolor;

	#ifdef HORIZON_CLIP
		color.rgb *= saturate(dot(normalize(viewPos), up) * HORIZON_CLIP_TRANSITION - (HORIZON_CLIP_HEIGHT * HORIZON_CLIP_TRANSITION));
	#endif

    #if DITHERING >= 2
		color.rgb += ditherColor(gl_FragCoord.xy);
	#endif
	gl_FragData[0] = color; //gcolor
}