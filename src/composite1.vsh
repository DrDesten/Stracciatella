out vec2 coord;

void main() {
	coord = gl_Vertex.xy * 0.5;

	gl_Position = gl_Vertex * 2 - 1;
	gl_Position.xy /= 4;
	gl_Position.xy -= .75;
}