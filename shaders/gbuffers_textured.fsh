

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"

#ifdef CUSTOM_LIGHTMAP
	uniform float customLightmapBlend;
#endif

flat in vec2 lmcoord;
noperspective in vec2 coord;
flat in vec4 glcolor;

#ifdef FOG

	#include "/lib/fog_sky.glsl"

	in vec3 viewPos;

	uniform float far;
	uniform mat4  gbufferModelViewInverse;

#endif

/* DRAWBUFFERS:01 */
void main() {
	vec4 color = getAlbedo(coord) * glcolor;

	#ifdef FOG
		float fog = fogFactor(viewPos, far, gbufferModelViewInverse);
		color.a  *= (1-fog);
		color.a  -= Bayer4(gl_FragCoord.xy) * 0.05;
	#endif

    #if DITHERING >= 2
		color.rgb += ditherColor(gl_FragCoord.xy);
	#endif
	gl_FragData[0] = color; //gcolor
	gl_FragData[1] = vec4(lmcoord, (254./255), 1);
}