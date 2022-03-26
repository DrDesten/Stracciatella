#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/composite_basics.glsl"

vec2 coord = gl_FragCoord.xy * screenSizeInverse * MC_RENDER_QUALITY;

vec4 textureBicubicComplexOpt(sampler2D sampler, vec2 coord, vec2 samplerSize, vec2 samplerSizeInverse) {
    vec4  totalData  = vec4(0);
    float totalWeight = 0;

    vec2 icoord   = coord * samplerSize;
    vec2 pixCoord = fract(icoord);

    for (int x = -1; x <= 2; x++) {
        for (int y = -1; y <= 2; y++) {

            vec4  sampleData = texelFetch(colortex0, ivec2(icoord) + ivec2(x,y), 0);
			float weight     = bell(pixCoord.x - x) * bell(pixCoord.y - y);

			totalData   += sampleData * weight;
			totalWeight += weight;
        
        }
    }

	return totalData / totalWeight;
}

/* DRAWBUFFERS:0 */
void main() {
	#ifdef HQ_UPSCALING
	//vec3 color = textureBicubicComplexOpt(colortex0, coord * MC_RENDER_QUALITY, screenSize * (1./MC_RENDER_QUALITY), screenSizeInverse * MC_RENDER_QUALITY).rgb;
	vec3 color = textureBicubic(colortex0, coord, screenSize * (1./MC_RENDER_QUALITY), screenSizeInverse * MC_RENDER_QUALITY).rgb;
	#else
	vec3 color = getAlbedo(coord);
	#endif
	gl_FragColor = vec4(color, 1.0);
}

/*
#ifdef HQ_UPSCALING
dummy code (not even code lol)
#endif
*/