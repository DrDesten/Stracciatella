#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/core/kernels.glsl"
#include "/lib/vertex_transform_simple.glsl"

out vec2 lmcoord;
flat out vec4 glcolor;
out vec3 viewPos;
flat out int materialId;

void main() {
    glcolor     = gl_Color;
    lmcoord     = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    viewPos     = getView();
    materialId  = dhMaterialId;
    gl_Position = ftransform();
}