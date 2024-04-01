#include "/lib/settings.glsl"
#include "/core/math.glsl"

in vec2 lmcoord;
flat in vec4 glcolor;


/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 FragOut0;

void main() {
    FragOut0 = glcolor;
}