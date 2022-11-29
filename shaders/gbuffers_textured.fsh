#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"
#ifndef INCLUDE_UNIFORM_float_customLightmapBlend
#define INCLUDE_UNIFORM_float_customLightmapBlend
uniform float customLightmapBlend;
#endif

#ifndef INCLUDE_UNIFORM_float_frameTimeCounter
#define INCLUDE_UNIFORM_float_frameTimeCounter
uniform float frameTimeCounter;
#endif
#include "/lib/lightmap.glsl"

flat in vec2 lmcoord;
noperspective in vec2 coord;
flat in vec4 glcolor;

#ifdef FOG

	#include "/lib/sky.glsl"

	in vec3 viewPos;
#ifndef INCLUDE_UNIFORM_float_far
#define INCLUDE_UNIFORM_float_far
uniform float far;
#endif

#ifndef INCLUDE_UNIFORM_mat4_gbufferModelViewInverse
#define INCLUDE_UNIFORM_mat4_gbufferModelViewInverse
uniform mat4 gbufferModelViewInverse;
#endif
#endif

/* DRAWBUFFERS:01 */
layout(location = 0) out vec4 FragOut0;
layout(location = 1) out vec4 FragOut1; // Even if only two channels are used, I need to set alpha in order for blending to not fuck up
void main() {
	vec4 color = getAlbedo(coord) * glcolor;
	
	color.rgb *= getCustomLightmap(vec3(lmcoord, glcolor.a), customLightmapBlend);

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
	FragOut1 = vec4( encodeLightmapData(vec4(0,0,1,1)), 1,1 );
}