

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"

uniform vec4  entityColor;

#ifdef CUSTOM_LIGHTMAP
	uniform float customLightmapBlend;
#endif

flat in vec2 lmcoord;
in vec2 coord;
flat in vec4 glcolor;
in vec3 viewPos;

/* DRAWBUFFERS:01 */
layout(location = 0) out vec4 FragOut0;
#ifdef MC_GL_VENDOR_INTEL
layout(location = 1) out vec2 FragOut1;
#else
layout(location = 1) out uint FragOut1;
#endif
void main() {
	vec4 color = getAlbedo(coord) * glcolor;
	color.rgb  = mix(color.rgb, entityColor.rgb, entityColor.a);
	
    #if DITHERING >= 2
		color.rgb += ditherColor(gl_FragCoord.xy);
	#endif
	
	FragOut0 = color; //gcolor
    if (FragOut0.a < 0.1) discard;
	FragOut1 = encodeLightmapData(vec4(lmcoord, 1,0));
}