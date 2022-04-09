#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/composite_basics.glsl"
#include "/lib/fog_sky.glsl"

uniform vec3  up;

vec2 coord = gl_FragCoord.xy * screenSizeInverse;

uniform mat4 gbufferProjectionInverse;
vec3 toView(vec3 clippos) { // Clippos to viewpos
    return unprojectPerspectiveMAD(clippos, gbufferProjectionInverse);
}

/* DRAWBUFFERS:0 */
void main() {
	float depth = getDepth(coord);
	vec3 color;
	if (depth >= 1) {

		vec3 viewDir = normalize(toView(vec3(coord, depth) * 2 - 1));
		vec4 sky     = getSkyColor_fogArea(viewDir, vec3(0), up, vec3(0), vec3(0), 0);
		color        = sky.rgb;

	} else {
		color = getAlbedo(coord);
	}

	#if DITHERING >= 1
		color += ditherColor(gl_FragCoord.xy);
	#endif
	gl_FragData[0] = vec4(color, 1.0); //gcolor
}