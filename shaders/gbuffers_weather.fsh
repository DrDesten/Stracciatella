

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"
#include "/lib/lightmap.glsl"

#ifdef CUSTOM_LIGHTMAP
	uniform float customLightmapBlend;
#endif

flat in vec2 lmcoord;
in vec2 coord;
flat in vec4 glcolor;

#if RAIN_DETECTION_MODE == 0
uniform float temperature;
#endif

#ifdef RAIN_EFFECTS
/* DRAWBUFFERS:03 */
#else
/* DRAWBUFFERS:0 */
#endif
void main() {
	vec4 color = getAlbedo(coord) * glcolor;

	#ifdef RAIN_EFFECTS

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

	#ifndef CUSTOM_LIGHTMAP
	color.rgb *= getLightmap(lmcoord);
	#else
	color.rgb *= getCustomLightmap(lmcoord, customLightmapBlend, 1);
	#endif


    #if DITHERING >= 2
		color.rgb += ditherColor(gl_FragCoord.xy);
	#endif
	gl_FragData[0] = color; //gcolor
	#ifdef RAIN_EFFECTS
	gl_FragData[1] = vec4(rain, 0, 0, 0.25);
	#endif
}