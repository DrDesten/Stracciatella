#include "/lib/settings.glsl"
#include "/lib/blending.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/core/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"

#include "/core/dh/textures.glsl"
#include "/core/dh/transform.glsl"
#include "/core/transform.glsl"

uniform vec2 screenSizeInverse;

#ifdef FOG

	#include "/lib/sky.glsl"

	uniform mat4  gbufferModelViewInverse;
	uniform int   isEyeInWater;
	uniform float far;

	#ifdef CUSTOM_SKY
		uniform float daynight;
	#endif

	uniform vec3  sunDir;
	uniform vec3  up;
	uniform float sunset;

#endif

uniform float rainStrength;

in vec2 coord;
flat in vec4 glcolor;
in vec3 viewPos;

/* DRAWBUFFERS:01 */
layout(location = 0) out vec4 FragOut0;
layout(location = 1) out vec2 FragOut1;
void main() {
	vec4 color = getAlbedo(coord) * glcolor;
	color.a    = fstep(0.1, color.a); // Make clouds solid

	color.rgb  = mix(color.rgb, vec3(luminance(color.rgb)) * vec3(0.58,0.6,0.7), rainStrength);

#ifdef DISTANT_HORIZONS
	vec3 screenPos = vec3(gl_FragCoord.xy * screenSizeInverse, gl_FragCoord.z);
	vec3 dhViewPos = screenToViewDH(vec3(screenPos.xy, getDepthDH(screenPos.xy)));
	vec3 dhScreenEquivalent = backToClip(dhViewPos) * .5 + .5;

	if (dhScreenEquivalent.z < screenPos.z) {
		discard;
	}
#endif

#ifdef FOG

	float fog = fogFactor(viewPos, min(far * 2, 350), gbufferModelViewInverse);

	#ifndef CUSTOM_SKY
		color.rgb = mix(color.rgb, getSkyColor(normalize(viewPos), sunDir, up, sunset), fog);
	#else
		color.rgb = mix(color.rgb, getSkyColor(normalize(viewPos), sunDir, up, sunset, rainStrength, daynight), fog);
	#endif

#endif

#if DITHERING >= 1
	color.rgb += ditherColor(gl_FragCoord.xy);
#endif

	color.rgb = blendColor(color.rgb);
	
	FragOut0 = color; //gcolor
    if (FragOut0.a < 0.1) discard;
	FragOut1 = encodeLightmapData(vec4(1));
}