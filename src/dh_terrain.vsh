#include "/lib/settings.glsl"
#include "/core/math.glsl"

out vec2 lmcoord;
flat out vec4 glcolor;

void main() {
    glcolor = gl_Color;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    
    gl_Position = ftransform();
}