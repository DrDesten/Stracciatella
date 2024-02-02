out vec2 coord;

void main() {
	coord = gl_Vertex.xy;

	gl_Position = gl_Vertex * 2 - 1;
	gl_Position.xy /= 3;
	gl_Position.xy -= 2./3.;
}