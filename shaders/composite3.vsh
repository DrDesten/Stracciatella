#if ! defined INCLUDE_COMPOSITE3_VSH
#define INCLUDE_COMPOSITE3_VSH

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"

void main() {
	#ifdef POST_PROCESS_SHADERS
	gl_Position = gl_Vertex * 2 - 1;
	#else
	gl_Position = vec4(-5); // Move it offscreen to discard (for OF versions not supporting shader config program toggling)
	gl_Position = gl_Vertex * 2 - 1;
	#endif
}

#endif