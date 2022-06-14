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
layout(location = 0) out vec4 FragOut0;
layout(location = 1) out uint FragOut1;
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
	
	FragOut0 = color; //gcolor
    if (FragOut0.a < 0.1) discard;
	FragOut1 = vec4toUI(vec4(lmcoord, 1,0));
}