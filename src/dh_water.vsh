#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/core/kernels.glsl"
#include "/lib/vertex_transform_simple.glsl"


out vec2 lmcoord;
out vec2 coord;
flat out vec4 glcolor;
out vec3 viewPos;
flat out int materialId;

void main() {
    lmcoord    = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    glcolor    = gl_Color;
    materialId = dhMaterialId;
    
    vec4 vertexPos = gl_Vertex;

    // Move down to match vanilla
    if (materialId == DH_BLOCK_WATER) {
        vertexPos.y -= 1.8/16.0;
    }

    viewPos     = getView(vertexPos);
    gl_Position = getPosition(vertexPos);
}