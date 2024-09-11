#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/core/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"

in vec2 coord;

#ifdef AURORA
    in float isAurora;
#endif

#ifdef HORIZON_CLIP
    uniform vec3 up;
    in vec3 viewPos;
#endif

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 FragOut0;
void main() {
	vec4 color = getAlbedo(coord);

	#ifdef HORIZON_CLIP
		color.rgb *= saturate(dot(normalize(viewPos), up) * HORIZON_CLIP_TRANSITION - (HORIZON_CLIP_HEIGHT * HORIZON_CLIP_TRANSITION));
	#endif

#if DITHERING >= 2
    color.rgb += ditherColor(gl_FragCoord.xy);
#endif

	FragOut0 = color;
    
#ifdef AURORA

    if (isAurora == 1) {
        vec4 aurora = vec4(1);

        aurora.rgb = vec3(0,1,0.5) * (sin(coord.x * TWO_PI * 20) * .4 + .6);

        aurora.a *= exp2(-(coord.y - 0.1) * 10);

        aurora.a *= 1 - sq(sqmag(coord * 2 - 1));
        FragOut0 = vec4(aurora.rgb * aurora.a, 1);

        //FragOut0.rgb = vec3(noise(coord.x * 10) * 0.5);
    }

#endif

}