#if ! defined INCLUDE_GBUFFERS_TEXTURED_VSH
#define INCLUDE_GBUFFERS_TEXTURED_VSH

#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/core/kernels.glsl"
#include "/lib/vertex_transform_simple.glsl"

flat out vec2 lmcoord;
flat out vec4 glcolor;

#ifdef AGRESSIVE_OPTIMISATION
    noperspective out vec2 coord;
    #ifdef FOG
    flat out vec3 viewPos;
    #endif
#else
    out vec2 coord;
    #ifdef FOG
    out vec3 viewPos;
    #endif
#endif


void main() {
	gl_Position = ftransform();
	coord   = getCoord();
	lmcoord = getLmCoord();
	glcolor = gl_Color;

	#ifdef FOG
	viewPos = getView();
	#endif
}

#endif