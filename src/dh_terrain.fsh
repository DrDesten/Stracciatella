#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/core/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"

uniform float far;

in vec2 lmcoord;
flat in vec4 glcolor;
in vec3 viewPos;

/* DRAWBUFFERS:01 */
layout(location = 0) out vec4 FragOut0;
layout(location = 1) out vec2 FragOut1;

void main() {
    if (length(viewPos) < far) {discard;}

    FragOut0 = glcolor;
	FragOut1 = encodeLightmapData(vec4(lmcoord, 1,0));
}