#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"

void main() {
	#if defined FXAA || defined HQ_UPSCALING
	gl_Position = gl_Vertex * 2 - 1;
	#else
	gl_Position = vec4(10, 10, 0, 1); // Move it offscreen to discard (for OF versions not supporting shader config program toggling)
	#endif
}