
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/core/kernels.glsl"
#include "/lib/composite_basics.glsl"
#include "/core/transform.glsl"

/*
// Post Process Shaders
const int colortex7Format = RGBA16F;
*/

vec2 coord = gl_FragCoord.xy * screenSizeInverse;

#if defined PP_PREPASS

const bool colortex0MipmapEnabled = true;

/* DRAWBUFFERS:7 */
layout(location = 0) out vec4 FragOut0;
void main() {
	const int iter   = 10;
	float     weight = 0;
	vec3      lodSum = vec3(0);
	for (int lod = 1; lod < iter; lod++) {
		float w  = sq(lod);
		lodSum  += textureLod(colortex0, coord, lod).rgb * w;
		weight  += w;
	}
	lodSum /= weight;

	vec3 color = lodSum;
	FragOut0 = vec4(color, 1);
}

#endif

#if defined PP_MAIN

uniform sampler2D colortex7;
const bool colortex0MipmapEnabled = true;
const bool colortex7MipmapEnabled = true;
vec4 getBuffer(vec2 coord) { return texture(colortex7, coord); }
vec4 getBufferLod(vec2 coord, float lod) { return textureLod(colortex7, coord, lod); }

uniform float nearInverse;
uniform float near;
uniform float far;

uniform vec3 sunPosition;

uniform float frameTimeCounter;


uniform sampler2D colortex1;
vec4 getLightmap(vec2 coord) {
    return vec2x16to4(texture(colortex1, coord).xy);
}

vec4 vectorBlur(sampler2D tex, vec2 coord, vec2 vector, int samples) {
	vec4 color      = vec4(0);
	vec2 sample     = coord;
	vec2 sampleStep = vector / samples;

	for (int i = 0; i < samples; i++) {
		color  += texture(tex, sample);
		sample += sampleStep;
	}

	return color / samples;
}

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 FragOut0;
void main() {
	vec3 baseColor  = getAlbedo(coord);
	vec4 bufferData = getBuffer(coord);

	vec4 b  = bufferData;
	vec4 bn = getBuffer(coord + 10 * vec2(0, screenSizeInverse.y));
	vec4 bs = getBuffer(coord - 10 * vec2(0, screenSizeInverse.y));
	vec4 be = getBuffer(coord + 10 * vec2(screenSizeInverse.x, 0));
	vec4 bw = getBuffer(coord - 10 * vec2(screenSizeInverse.x, 0));
	
	float lb  = luminance(b.rgb);
	float lbn = luminance(bn.rgb);
	float lbs = luminance(bs.rgb);
	float lbe = luminance(be.rgb);
	float lbw = luminance(bw.rgb);

	vec2 flow = vec2(
		lbn - lbs,
		lbe - lbw
	);
	vec2 flowDir = normalize(flow);
	
	vec2 flowR = vec2(bn.r - bs.r, be.r - bw.r);
	vec2 flowG = vec2(bn.g - bs.g, be.g - bw.g);
	vec2 flowB = vec2(bn.b - bs.b, be.b - bw.b);
	
	vec3 color = vec3(flow, 0) * .5 + .5;

	color = vec3(
		vectorBlur(colortex0, coord, flowR * 0.2, 8).r,
		vectorBlur(colortex0, coord, flowG * 0.2, 8).g,
		vectorBlur(colortex0, coord, flowB * 0.2, 8).b
	);

	FragOut0   = vec4(color, 1);
}

#endif