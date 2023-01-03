#if ! defined INCLUDE_GBUFFERS_TEXTURED_FSH
#define INCLUDE_GBUFFERS_TEXTURED_FSH

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"
#if ! defined INCLUDE_UNIFORM_float_customLightmapBlend
#define INCLUDE_UNIFORM_float_customLightmapBlend
uniform float customLightmapBlend; 
#endif

#if ! defined INCLUDE_UNIFORM_float_frameTimeCounter
#define INCLUDE_UNIFORM_float_frameTimeCounter
uniform float frameTimeCounter; 
#endif
#include "/lib/lightmap.glsl"

flat in vec2 lmcoord;
flat in vec4 glcolor;

#ifdef AGRESSIVE_OPTIMISATION
    noperspective in vec2 coord;
    #ifdef FOG
    flat in vec3 viewPos;
    #endif
#else
    in vec2 coord;
    #ifdef FOG
    in vec3 viewPos;
    #endif
#endif

#ifdef FOG
	#include "/lib/sky.glsl"
#if ! defined INCLUDE_UNIFORM_float_far
#define INCLUDE_UNIFORM_float_far
uniform float far; 
#endif

#if ! defined INCLUDE_UNIFORM_mat4_gbufferModelViewInverse
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

#endif