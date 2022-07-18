#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"
#include "/lib/lightmap.glsl"


uniform float customLightmapBlend;

flat in vec2 lmcoord;
noperspective in vec2 coord;
flat in vec4 glcolor;

#ifdef FOG

	#include "/lib/fog_sky.glsl"

	in vec3 viewPos;

	uniform float far;
	uniform mat4  gbufferModelViewInverse;

#endif

/* DRAWBUFFERS:01 */
layout(location = 0) out vec4 FragOut0;
layout(location = 1) out vec2 FragOut1;
void main() {
	vec4 color = getAlbedo(coord) * glcolor;
	
	color.rgb *= getCustomLightmap(lmcoord, customLightmapBlend, glcolor.a);

	#ifdef FOG
		float fog = fogFactor(viewPos, far, gbufferModelViewInverse);
		color.a  *= (1-fog);
		color.a  -= Bayer4(gl_FragCoord.xy) * 0.05;
	#endif

    #if DITHERING >= 2
		color.rgb += ditherColor(gl_FragCoord.xy);
	#endif
	
	FragOut0 = color; //gcolor
    if (FragOut0.a < 0.1) discard;
	FragOut1 = encodeLightmapData(vec4(0,0,1,1));
}