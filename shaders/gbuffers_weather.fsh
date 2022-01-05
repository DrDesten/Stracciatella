#version 120

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"

#ifdef CUSTOM_LIGHTMAP
	uniform float customLightmapBlend;
#endif

varying vec2 lmcoord;
varying vec2 coord;
varying vec4 glcolor;

uniform float temperature;

#ifdef RAIN_EFFECTS
/* DRAWBUFFERS:03 */
#else
/* DRAWBUFFERS:0 */
#endif
void main() {
	vec4 color = getAlbedo(coord) * glcolor;

	#ifndef CUSTOM_LIGHTMAP
	color.rgb *= getLightmap(lmcoord);
	#else
	color.rgb *= getCustomLightmap(lmcoord, customLightmapBlend, 1);
	#endif

	#ifdef RAIN_EFFECTS
		float rain = 0;
		if (temperature >= 0.15) { // Rain
			rain    = fstep(0.01, color.a);
			color.a = rain * RAIN_OPACITY;
		}
	#endif

    #if DITHERING >= 2
		color.rgb += ditherColor(gl_FragCoord.xy);
	#endif
	FD0 = color; //gcolor
	#ifdef RAIN_EFFECTS
	FD1 = vec4(rain, 0, 0, 0.25);
	#endif
}