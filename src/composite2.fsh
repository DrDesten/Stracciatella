#include "/lib/settings.glsl"
#include "/core/math.glsl"

const bool colortex5MipmapEnabled = true;
uniform sampler2D colortex5;

in vec2 coord;

/* DRAWBUFFERS:6 */
layout(location = 0) out vec4 FragOut0;
void main() {
	FragOut0 = texture(colortex5, coord);
}
