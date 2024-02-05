#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/core/kernels.glsl"
#include "/lib/composite_basics.glsl"

uniform sampler2D colortex6;

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

vec4 textureBicubicSharp(sampler2D sampler, vec2 coord, vec2 samplerSize, vec2 pixelSize) {
    coord = coord * samplerSize - 0.5;

    vec2 fxy = fract(coord);
    coord -= fxy;

    vec4 xcubic = cubic(fxy.x);
    vec4 ycubic = cubic(fxy.y);

    vec4 c = coord.xxyy + vec2 (-0.5, +1.5).xyxy;

    vec4 s = vec4(xcubic.xz + xcubic.yw, ycubic.xz + ycubic.yw);
    vec4 offset = c + vec4 (xcubic.yw, ycubic.yw) / s;

    offset *= pixelSize.xxyy;

    vec4 sample0 = texture(sampler, offset.xz);
    vec4 sample1 = texture(sampler, offset.yz);
    vec4 sample2 = texture(sampler, offset.xw);
    vec4 sample3 = texture(sampler, offset.yw);

	vec4 average = (sample0 + sample1 + sample3 + sample3) * 0.25;

    float sx = s.x / (s.x + s.y);
    float sy = s.z / (s.z + s.w);

    return mix(
        mix(sample3, sample2, sx), 
        mix(sample1, sample0, sx)
    , sy);
}


/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 FragOut0;
void main() {
#ifdef HQ_UPSCALING
	//vec3 color = textureBicubicComplexOpt(colortex0, coord * MC_RENDER_QUALITY, screenSize * (1./MC_RENDER_QUALITY), screenSizeInverse * MC_RENDER_QUALITY).rgb;
	vec3 color = textureBicubicSharp(colortex0, coord, screenSize * (1./MC_RENDER_QUALITY), screenSizeInverse * MC_RENDER_QUALITY).rgb;
#else
	vec3 color = getAlbedo(coord);
	color = color * 0.5 + texture(colortex6, coord / 81 + (2./3. + 2./9. + 2./27. + 2./81.)).rgb * 0.5;
#endif
	//color = FXAA311Upscale(coord, 2);
	FragOut0 = vec4(color, 1.0);
}

/*
#ifdef HQ_UPSCALING
dummy code (not even code lol)
#endif
*/