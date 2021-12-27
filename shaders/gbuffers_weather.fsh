#version 120

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"

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
	color.rgb *= getLightmap(lmcoord);

	#ifdef RAIN_EFFECTS
		float rain = 0;
		if (temperature >= 0.15) { // Rain
			rain    = step(0.01, color.a);
			color.a = rain * 0.5;
		}
	#endif

	FD0 = color; //gcolor
	#ifdef RAIN_EFFECTS
	FD1 = vec4(rain, 0, 0, 0.25);
	#endif
}