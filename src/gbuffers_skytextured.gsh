#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/lib/vertex_transform.glsl"

uniform float frameTimeCounter;

in  vec2[3] _coord;
out vec2    coord;

#ifdef HORIZON_CLIP
in  vec3[3] _viewPos;
out vec3    viewPos;
#endif

#ifdef AURORA
in  int[3] vertexId;
out float  isAurora;
#endif

layout (triangles) in;
layout (triangle_strip, max_vertices = 13) out;
void main() {

#ifdef AURORA
    isAurora = 0;
#endif

    // Passthrough of original primitives

	gl_Position = gl_in[0].gl_Position;
	coord       = _coord[0];
    #ifdef HORIZON_CLIP
    viewPos     = _viewPos[0];
    #endif
    EmitVertex();

	gl_Position = gl_in[1].gl_Position;
	coord       = _coord[1];
    #ifdef HORIZON_CLIP
    viewPos     = _viewPos[1];
    #endif
    EmitVertex();

	gl_Position = gl_in[2].gl_Position;    
	coord       = _coord[2];
    #ifdef HORIZON_CLIP
    viewPos     = _viewPos[2];
    #endif
    EmitVertex();

    EndPrimitive();

#ifdef AURORA

    // New vertices

    isAurora = 1;

    #define AURORA_HEIGHT 500
    #define AURORA_SIZE 800
    #define AURORA_STRIP_LENGTH 5

    float radius = rand(vertexId[0] << 4) * 2000 + 1000;
    float start  = rand(vertexId[0]) * TWO_PI;
    float len    = rand(vertexId[0] << 2) * PI + PI;
    len         *= 0.5 * (2000 / radius);

    for (int i = 0; i < AURORA_STRIP_LENGTH; i++) {

        float progression = float(i) / (AURORA_STRIP_LENGTH - 1);

        float angle = start + len * progression;
        float seed = angle + frameTimeCounter * 0.2 + radius;
        float offset = noise(seed) + noise(seed * 1.5) * 0.5 + noise(seed * 2) * 0.25; 
        vec2 position = vec2(sin(angle), cos(angle)) * (radius - offset * 250);

        gl_Position = playerToClip( vec3(position.x, AURORA_HEIGHT, position.y) );
        gl_Position.z /= 8;
        coord = vec2(progression, 0);
        EmitVertex();

        gl_Position = playerToClip( vec3(position.x, AURORA_HEIGHT + AURORA_SIZE, position.y) );
        gl_Position.z /= 8;
        coord = vec2(progression, 1);
        EmitVertex();

    }
    
    EndPrimitive();   

#endif
}