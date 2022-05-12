

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"

#ifdef CUSTOM_STARS
uniform mat4 gbufferModelViewInverse;
out vec3 playerPos;
#endif

out vec4 starData; //rgb = star color, a = flag for weather or not this pixel is a star.
out vec3 viewPos;

void main() {
	gl_Position = ftransform();
	starData    = vec4(gl_Color.rgb, float(gl_Color.r == gl_Color.g && gl_Color.g == gl_Color.b && gl_Color.r > 0.0));
	viewPos     = mat3(gl_ModelViewMatrix) * gl_Vertex.xyz;
	
	#ifdef CUSTOM_STARS
	playerPos   = mat3(gbufferModelViewInverse) * viewPos - gbufferModelViewInverse[3].xyz;
	#endif
}