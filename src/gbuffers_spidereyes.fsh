#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"

in vec2 coord;
flat in vec4 glcolor;

/* DRAWBUFFERS:01 */
layout(location = 0) out vec4 FragOut0;
layout(location = 1) out vec2 FragOut1;
void main() {
	vec4 color = getAlbedo(coord) * glcolor;

	FragOut0 = color; //gcolor
    if (FragOut0.a < 0.1) discard;
	FragOut1 = encodeLightmapData(vec4(1));
}