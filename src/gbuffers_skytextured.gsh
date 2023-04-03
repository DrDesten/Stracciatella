#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/vertex_transform.glsl"

layout (triangles) in;
layout (triangle_strip, max_vertices = 13) out;

in vec2[3] textureCoordinate;
in int[3] vertexId;

out vec2 coord;
out float isAurora;

void main() {

    // Passthrough of original primitives

    isAurora = 0;

	gl_Position = gl_in[0].gl_Position;
	coord = textureCoordinate[0];
    EmitVertex();

	gl_Position = gl_in[1].gl_Position;
	coord = textureCoordinate[1];
    EmitVertex();

	gl_Position = gl_in[2].gl_Position;    
	coord = textureCoordinate[2];
    EmitVertex();

    EndPrimitive();
    
    // New vertices

    isAurora = 1;

    #define AURORA_HEIGHT 200
    #define AURORA_SIZE 60
    #define AURORA_STRIP_LENGTH 5
    vec2 vertices[AURORA_STRIP_LENGTH];
    
    if (vertexId[0] == 0) 
        vertices = vec2[](
            vec2(200,-100),
            vec2(250,0),
            vec2(200,100),
            vec2(300,200),
            vec2(250,300)
        );
    else if (vertexId[0] == 1)
        vertices = vec2[](
            vec2(-250,300),
            vec2(-300,200),
            vec2(-200,100),
            vec2(-250,0),
            vec2(-200,-100)
        );
    else if (vertexId[0] == 2)
        vertices = vec2[](
            vec2(100,-100),
            vec2(150,0),
            vec2(100,100),
            vec2(200,200),
            vec2(150,300)
        );
    else if (vertexId[0] == 3)
        vertices = vec2[](
            vec2(-150,300),
            vec2(-200,200),
            vec2(-100,100),
            vec2(-150,0),
            vec2(-100,-100)
        );

    for (int i = 0; i < AURORA_STRIP_LENGTH; i++) {

        float position = float(i) / (AURORA_STRIP_LENGTH - 1);

        gl_Position = playerToClip(
            vec3(vertices[i].x, AURORA_HEIGHT, vertices[i].y)
        );
        coord = vec2(position, 1);
        EmitVertex();

        gl_Position = playerToClip(
            vec3(vertices[i].x, AURORA_HEIGHT - AURORA_SIZE, vertices[i].y)
        );
        coord = vec2(position, 0);
        EmitVertex();

    }
    
    EndPrimitive();   

	/* gl_Position = playerToClip(vertices[1]);
    EmitVertex();

	gl_Position = playerToClip(vertices[2]);
    EmitVertex();

    EndPrimitive();   */ 
}