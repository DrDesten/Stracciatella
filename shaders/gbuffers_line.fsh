

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"

flat in vec4 glcolor;

/* DRAWBUFFERS:01 */
void main() {
	vec4 color = glcolor;
    
    #if DITHERING >= 2
		color.rgb += ditherColor(gl_FragCoord.xy);
	#endif

	gl_FragData[0] = color; //gcolor
	gl_FragData[1] = vec4(1,1,0,1);
}