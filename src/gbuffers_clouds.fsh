#ifndef DISTANT_HORIZONS

#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/core/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"

#if FOG != 0

#include "/lib/sky.glsl"

uniform int   isEyeInWater;
uniform float far;

uniform vec3  sunDir;
uniform vec3  up;
uniform float sunset;

#endif

uniform float rainStrength;

in vec2 coord;
flat in vec4 glcolor;
in vec3 viewPos;
in vec3 playerPos;

/* DRAWBUFFERS:01 */
layout(location = 0) out vec4 FragOut0;
layout(location = 1) out vec2 FragOut1;
void main() {
	vec4 color = getAlbedo(coord) * glcolor;
	color.a    = fstep(0.1, color.a); // Make clouds solid
	color.rgb  = mix(color.rgb, vec3(luminance(color.rgb)) * vec3(0.58,0.6,0.7), rainStrength);

#if FOG != 0

	float dist = sqmag(playerPos.xz);
	float end  = sq(far * 2 * SQRT2);
	float fog  = smoothstep(0, end, dist);

	vec3 playerDir;
	#if defined END 
	playerDir = normalize(playerPos);
	#endif

	color.rgb = mix(color.rgb, getSkyColor(normalize(viewPos), playerDir), fog);

#endif

#if DITHERING >= 1
	color.rgb += ditherColor(gl_FragCoord.xy);
#endif

	FragOut0 = color; //gcolor
    if (FragOut0.a < 0.1) discard;
	FragOut1 = encodeLightmapData(vec4(1));
}

#else 

void main() {} // DISTANT_HORIZONS

#endif