#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/core/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"

uniform vec4  entityColor;

uniform float customLightmapBlend;

flat in vec2 lmcoord;
in      vec2 coord;
flat in vec4 glcolor;
in      vec3 viewPos;

/* DRAWBUFFERS:01 */
layout(location = 0) out vec4 FragOut0;
layout(location = 1) out vec4 FragOut1; // Even if only two channels are used, I need to set alpha in order for blending to not fuck up
void main() {
	vec4 color = getAlbedo(coord) * glcolor;
	color.rgb  = mix(color.rgb, entityColor.rgb, entityColor.a);

	// Todo:
	// Entity Shadows render here and they are fucked up
	// -> Entity shadows have bullbright lightmap coordinates, and they overwrite whatever terrain is below them.
	// Temporary Solution:
	// Alpha-Discard at 0.5 
	// -> Removes entity shadows
	
#if DITHERING >= 2
	color.rgb += ditherColor(gl_FragCoord.xy);
#endif
	
	FragOut0 = color; //gcolor
    if (FragOut0.a < 0.5) discard;
	FragOut1 = vec4( encodeLightmapData(vec4(lmcoord, 1, 0)), 1, 1 );
}