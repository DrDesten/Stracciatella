out vec2 coord;

void main() {
	coord = gl_Vertex.xy / 2;

	gl_Position = gl_Vertex * 2 - 1;
	gl_Position.xy /= 4;
	gl_Position.xy -= 1./2. + 1./4.;
}