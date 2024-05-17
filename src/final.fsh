#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/core/kernels.glsl"
#include "/core/sampler.glsl"
#include "/lib/composite_basics.glsl"

uniform sampler2D colortex6;

vec2 coord = gl_FragCoord.xy * screenSizeInverse * MC_RENDER_QUALITY;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 FragOut0;
void main() {
#ifdef HQ_UPSCALING
	vec3 color = textureBicubic(colortex0, coord, screenSize * (1./MC_RENDER_QUALITY), screenSizeInverse * MC_RENDER_QUALITY).rgb;
#else
	vec3 color = getAlbedo(coord);
	//color = color * 0.5 + texture(colortex6, coord / 16 + (1./2 + 1./4 + 1./8 + 1./16) - screenSizeInverse).rgb * 0.5;
#endif
	//color = FXAA311Upscale(coord, 2);
	FragOut0 = vec4(color, 1.0);
}

/*
#ifdef HQ_UPSCALING
dummy code (not even code lol)
#endif
*/