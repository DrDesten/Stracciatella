

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"

#ifdef CUSTOM_LIGHTMAP
	uniform float customLightmapBlend;
#endif

in vec2 lmcoord;
in vec2 coord;
flat in vec4 glcolor;
in vec3 viewPos;

/* DRAWBUFFERS:01 */
void main() {
	vec4 color = getAlbedo(coord);
	color.rgb *= glcolor.rgb;
	
	#ifndef CUSTOM_LIGHTMAP
	color.rgb *= getLightmap(lmcoord);
	#else
	color.rgb *= getCustomLightmap(lmcoord, customLightmapBlend, glcolor.a);
	#endif

    #if DITHERING >= 2
		color.rgb += ditherColor(gl_FragCoord.xy);
	#endif
	gl_FragData[0] = color; //gcolor
	gl_FragData[1] = vec4(lmcoord,0,1);
}