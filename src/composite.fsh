#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/composite_basics.glsl"
#include "/lib/transform.glsl"

const vec2 pixel = vec2(1) / vec2(16, 9);
vec2       coord = gl_FragCoord.xy * vec2(1./16, 1./9);

#ifdef COLORED_LIGHTS

const bool colortex5MipmapEnabled = true;

uniform sampler2D colortex4;
uniform sampler2D colortex5;

uniform int frameCounter;
uniform float nearInverse;

/* vec3 sampleEmissive(vec2 coord, float lod) {
	vec3 col = textureLod(colortex0, coord.xy, lod).rgb;
	col /= max(0.05, maxc(col));
	return col * textureLod(colortex2, coord.xy, lod).x * saturate(sqmag(saturate(coord.xy) - coord.xy) * -4 + 1);
} */

vec3 sampleEmissive(vec2 coord, float lod) {
	return textureLod(colortex5, coord.xy, lod).rgb * saturate(sqmag(saturate(coord.xy) - coord.xy) * -5 + 1);
}

/* vec3 gauss3x3(sampler2D tex, vec2 coord, vec2 pix) {
	return texture(tex, coord + .5 * pix.xy).rgb * .25 +
		   texture(tex, coord - .5 * pix.xy).rgb * .25 +
		   texture(tex, coord + .5 * vec2(pix.x, -pix.y)).rgb * .25 +
		   texture(tex, coord + .5 * vec2(-pix.x, pix.y)).rgb * .25;
} */
vec3 gauss3x3(sampler2D tex, vec2 coord, vec2 pix) {
	vec3 a = texture(tex, coord + .5 * pix.xy).rgb;
    vec3 b = texture(tex, coord - .5 * pix.xy).rgb;
    vec3 c = texture(tex, coord + .5 * vec2(pix.x, -pix.y)).rgb;
    vec3 d = texture(tex, coord + .5 * vec2(-pix.x, pix.y)).rgb;
	return a * .25 + (b * .25 + (c * .25 + (d * .25)));
}
vec4 gauss3x3full(sampler2D tex, vec2 coord, vec2 pix) {
	vec4 a = texture(tex, coord + .5 * pix.xy);
    vec4 b = texture(tex, coord - .5 * pix.xy);
    vec4 c = texture(tex, coord + .5 * vec2(pix.x, -pix.y));
    vec4 d = texture(tex, coord + .5 * vec2(-pix.x, pix.y));
	return a * .25 + (b * .25 + (c * .25 + (d * .25)));
}
vec3 gauss3x3Lod(sampler2D tex, vec2 coord, vec2 pix, float lod) {
	vec3 a = textureLod(tex, coord + .5 * pix.xy, lod).rgb;
    vec3 b = textureLod(tex, coord - .5 * pix.xy, lod).rgb;
    vec3 c = textureLod(tex, coord + .5 * vec2(pix.x, -pix.y), lod).rgb;
    vec3 d = textureLod(tex, coord + .5 * vec2(-pix.x, pix.y), lod).rgb;
	return a * .25 + (b * .25 + (c * .25 + (d * .25)));
}

vec4 gauss3x3LodHit(sampler2D tex, vec2 coord, vec2 pix, float lod) {
	vec3 a = textureLod(tex, coord + .5 * pix.xy, lod).rgb;
    vec3 b = textureLod(tex, coord - .5 * pix.xy, lod).rgb;
    vec3 c = textureLod(tex, coord + .5 * vec2(pix.x, -pix.y), lod).rgb;
    vec3 d = textureLod(tex, coord + .5 * vec2(-pix.x, pix.y), lod).rgb;
	return vec4(a * .25 + (b * .25 + (c * .25 + (d * .25))), mean(vec4(sum(a) > 0, sum(b) > 0, sum(c) > 0, sum(d) > 0)));
}

#endif

/* DRAWBUFFERS:4 */
layout(location = 0) out vec4 FragOut0;
void main() {
	
#ifdef COLORED_LIGHTS

	vec3 screenPos = vec3(coord, getDepth(coord));

	vec4 prevProj    = reprojectScreen(screenPos);
	vec2 prevCoord   = prevProj.xy;

	vec3  prevCol   = gauss3x3(colortex4, prevProj.xy, pixel * 0.75);
	float prevDepth = texture(colortex4, prevProj.xy).a;

	float sampleLod = max(log2(mean(screenSize * pixel)) + LIGHTMAP_COLOR_LOD_BIAS, 0); // Calculate appropiate sampling LoD
	vec2  jitter    = R2(frameCounter%1000) * pixel - (pixel * .5);
	vec3  color     = gauss3x3Lod(colortex5, coord + jitter, pixel, sampleLod) * 10;
	color = color / (color + 1.0);

	// Improves Accumulation by guessing pixel age and sample importance (there is no buffer space left for pixel age)
	float age = maxc(prevCol); age = age / (age + 0.025); // Estimates age using pixel brightness
	float sampleImportance = luminance(color.rgb); // Estimates sample importance using sample brightness
	float mixTweak = age * (sampleImportance) + (1 - sampleImportance); // If the age is high (value low), let more of the sample in, but only if there is something to sample
	mixTweak = mixTweak * (1 - LIGHTMAP_COLOR_FLICKER_RED) + LIGHTMAP_COLOR_FLICKER_RED; // Tweak value using user defined setting

	#if LIGHTMAP_COLOR_REJECTION == 0

		// Weak Rejection (coordinates and depth, high tolerances)
		float depthError = abs(linearizeDepthf(prevDepth, nearInverse) - linearizeDepthf(prevProj.z, nearInverse));
		float coordError = sqmag(saturate(prevProj.xy) - prevProj.xy);
		float rejection  = max(saturate(coordError * -2 + 1), saturate(depthError * -0.25 + 1));

	#elif LIGHTMAP_COLOR_REJECTION == 1

		// Normal Rejection (coordinates and depth, normal tolarance)
		float depthError = abs(linearizeDepthf(prevDepth, nearInverse) - linearizeDepthf(prevProj.z, nearInverse));
		float coordError = sqmag(saturate(prevProj.xy) - prevProj.xy);
		float rejection  = max(saturate(coordError * -4 + 1), saturate(depthError * -0.5 + 1));

	#elif LIGHTMAP_COLOR_REJECTION == 2

		// Strong Rejection (only coordinates, no fallback)
		float coordError = sqmag(saturate(prevProj.xy) - prevProj.xy);
		float rejection  = saturate(coordError * -4 + 1);

	#endif

	// if the mix blend is 0, new color is used
	// rejection is zero when history is fully rejected, causing the history to be removed (multiplied by zero)
	// if LIGHTMAP_COLOR_REGEN is 1, rejection == 0 will cause the new color to instantly fill the frame, while
	//    LIGHTMAP_COLOR_REGEN    0  will cause rejection to have no impact on the blend factor.
	color = mix(color, prevCol * rejection, LIGHTMAP_COLOR_BLEND * (rejection * LIGHTMAP_COLOR_REGEN + (1 - LIGHTMAP_COLOR_REGEN)) * mixTweak);
	
	FragOut0 = vec4(color, screenPos.z);

#endif
}

/*
LIGHTMAP_COLOR_REJECTION
*/