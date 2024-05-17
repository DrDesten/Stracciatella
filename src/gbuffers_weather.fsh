#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/core/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"

uniform float customLightmapBlend;
uniform float frameTimeCounter;
#include "/lib/lightmap.glsl"

flat in vec2 lmcoord;
in vec2 coord;
flat in vec4 glcolor;

#if RAIN_DETECTION_MODE == 0
uniform float playerTemperature;
#endif

#if RAIN_REFRACTION != 0
/* DRAWBUFFERS:03 */
layout(location = 0) out vec4 FragOut0;
layout(location = 1) out vec4 FragOut1;
#else
/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 FragOut0;
#endif
void main() {
	vec4 color = getAlbedo(coord) * glcolor;

#if RAIN_REFRACTION != 0

	float rain = 0;
	bool  isRain;

	#if RAIN_DETECTION_MODE == 0
	isRain = playerTemperature >= 0.15; // Rain (detected based on player playerTemperature)
	#elif RAIN_DETECTION_MODE == 1
	vec3 normalizedColor = normalize(color.rgb);
	isRain = saturate((color.b) - avg(color.rg)) > 0.25; // Rain (detected based on blue dominance)
	#endif
	if (isRain) {
		#if RAIN_REFRACTION == 1

		rain = color.a;

		#elif RAIN_REFRACTION == 2

		ivec2 texSize    = textureSize(gcolor, 0);
		vec2  texelCoord = coord * vec2(texSize) - 0.5;
		ivec2 texel      = ivec2(texelCoord) % texSize;
		vec2  frac       = fract(texelCoord);

		vec4 samples = vec4(
			texelFetch(gcolor, texel + ivec2(0, 0), 0).a,
			texelFetch(gcolor, texel + ivec2(1, 0), 0).a,
			texelFetch(gcolor, texel + ivec2(0, 1), 0).a,
			texelFetch(gcolor, texel + ivec2(1, 1), 0).a
		);
		float res = mix(
			mix(samples.x, samples.y, frac.x), 
			mix(samples.z, samples.w, frac.x),
			frac.y
		);
		rain = res;

		#endif

		color.a = diagosymmetricLift(color.a, RAIN_OPACITY * 2 - 1);
	}

#endif

	color.rgb *= getCustomLightmap(vec3(lmcoord, 1), customLightmapBlend);

#if DITHERING >= 2
	color.rgb += ditherColor(gl_FragCoord.xy);
#endif
	
	FragOut0 = color; //gcolor
    if (FragOut0.a < 1e-2) discard;
#if RAIN_REFRACTION != 0
	FragOut1 = vec4(rain, 0, 0, 1);
#endif
}