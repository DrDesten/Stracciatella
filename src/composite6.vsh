#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/core/kernels.glsl"

void main() {
	#ifdef POST_PROCESS_SHADERS
	gl_Position = gl_Vertex * 2 - 1;
	#else
	gl_Position = vec4(-5); // Move it offscreen to discard (for OF versions not supporting shader config program toggling)
	#endif
}