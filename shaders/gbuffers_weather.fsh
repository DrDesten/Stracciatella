#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"

uniform float customLightmapBlend;
uniform float frameTimeCounter;
#include "/lib/lightmap.glsl"

flat in vec2 lmcoord;
in vec2 coord;
flat in vec4 glcolor;

#if RAIN_DETECTION_MODE == 0
uniform float temperature;
#endif

#ifdef RAIN_REFRACTION
/* DRAWBUFFERS:03 */
layout(location = 0) out vec4 FragOut0;
layout(location = 1) out vec4 FragOut1;
#else
/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 FragOut0;
#endif
void main() {
	vec4 color = getAlbedo(coord) * glcolor;

	#ifdef RAIN_REFRACTION

		float rain = 0;

		#if RAIN_DETECTION_MODE == 0
		if (temperature >= 0.15) { // Rain (detected based on player temperature)
		#elif RAIN_DETECTION_MODE == 1
		vec3 normalizedColor = normalize(color.rgb);
		if (saturate((color.b) - mean(color.rg)) > 0.25) { // Rain (detected based on blue dominance)
		#endif

			rain    = fstep(0.01, color.a);
			color.a = rain * RAIN_OPACITY;
		}

	#endif

	color.rgb *= getCustomLightmap(vec3(lmcoord, 1), customLightmapBlend);

    #if DITHERING >= 2
		color.rgb += ditherColor(gl_FragCoord.xy);
	#endif
	
	FragOut0 = color; //gcolor
    if (FragOut0.a < 0.1) discard;
	#ifdef RAIN_REFRACTION
	FragOut1 = vec4(rain, 0, 0, 0.25);
	#endif
}