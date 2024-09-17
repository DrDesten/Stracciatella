#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/core/kernels.glsl"
#include "/lib/vertex_transform_simple.glsl"

flat out vec2 lmcoord;
flat out vec4 glcolor;

#if OPT_SAFE
    noperspective out vec2 coord;
    #if FOG != 0
    flat out vec3 viewPos;
    #endif
#else
    out vec2 coord;
    #if FOG != 0
    out vec3 viewPos;
    #endif
#endif


void main() {
	gl_Position = getPosition();
	coord       = getCoord();
	lmcoord     = getLmCoord();
	glcolor     = gl_Color;

	#if FOG != 0
	viewPos = getView();
	#endif

    #ifdef SMOOTHCAM
    gl_Position = vec4(-1);
    #endif
}