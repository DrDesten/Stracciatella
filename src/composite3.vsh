#include "/lib/vertex_transform_composite.glsl"

out vec2 coord;

void main() {
	coord = gl_Vertex.xy / 8;

	gl_Position = getPosition();
	gl_Position.xy /= 16;
	gl_Position.xy += 1./2. + 1./4. + 1./8. + 1./16.;
}