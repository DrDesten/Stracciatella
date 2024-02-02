#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/core/kernels.glsl"
#include "/lib/composite_basics.glsl"
#include "/lib/transform.glsl"
#include "/lib/colored_lights.glsl"

const vec2 pixel = vec2(1) / LIGHTMAP_COLOR_RES;
vec2       coord = gl_FragCoord.xy * pixel;

#ifdef COLORED_LIGHTS

const bool colortex5MipmapEnabled = true;

uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D colortex6;

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
	return a * .25 + b * .25 + c * .25 + d * .25;
}
vec3 gauss3x3Lod(sampler2D tex, vec2 coord, vec2 pix, float lod) {
	vec3 a = textureLod(tex, coord + .5 * pix.xy, lod).rgb;
    vec3 b = textureLod(tex, coord - .5 * pix.xy, lod).rgb;
    vec3 c = textureLod(tex, coord + .5 * vec2(pix.x, -pix.y), lod).rgb;
    vec3 d = textureLod(tex, coord + .5 * vec2(-pix.x, pix.y), lod).rgb;
	return a * .25 + b * .25 + c * .25 + d * .25;
}

vec4 gauss3x3LodHit(sampler2D tex, vec2 coord, vec2 pix, float lod) {
	vec3 a = textureLod(tex, coord + .5 * pix.xy, lod).rgb;
    vec3 b = textureLod(tex, coord - .5 * pix.xy, lod).rgb;
    vec3 c = textureLod(tex, coord + .5 * vec2(pix.x, -pix.y), lod).rgb;
    vec3 d = textureLod(tex, coord + .5 * vec2(-pix.x, pix.y), lod).rgb;
	return vec4(a * .25 + b * .25 + c * .25 + d * .25, avg(vec4(sum(a) > 0, sum(b) > 0, sum(c) > 0, sum(d) > 0)));
}

#endif

/* DRAWBUFFERS:4 */
layout(location = 0) out vec4 FragOut0;
void main() {

#ifdef COLORED_LIGHTS

	vec3 screenPos = vec3(coord, getDepth(coord));

	vec4 prevProj   = reprojectScreen(screenPos);
	vec2 prevCoord  = prevProj.xy;

	vec3  prevCol        = gauss3x3(colortex4, prevProj.xy, pixel);
	float prevImportance = getImportance(prevCol);
	float prevDepth      = texture(colortex4, prevProj.xy).a * 0.5 + 0.5;

	float sampleLod  = max(log2(maxc(screenSize * pixel)) + LIGHTMAP_COLOR_LOD_BIAS, 0); // Calculate appropiate sampling LoD
	vec2  jitter     = R2(frameCounter%1000) * pixel - (pixel * .5);
	//vec3  rawColor   = gauss3x3Lod(colortex5, coord + jitter, pixel, sampleLod);
	vec3  rawColor   = texture(colortex6, coord / 81 + (2./3. + 2./9. + 2./27. + 2./81.)).rgb;
	vec3  color      = rgb2oklab(sqrt(rawColor));
	float importance = getImportance(color);

	// Calculate mix value based on current and previous importance values
	// 0: new <=> 1: old
	prevImportance *= 2;
	importance      = sqsq(importance);
	float softmax   = min(1, exp(prevImportance) / (exp(prevImportance) + exp(importance)));
	float mixTweak  = softmax / (softmax + 0.05);

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
	color = mix(
		color, 
		prevCol * vec3(rejection, 1, 1), 
		LIGHTMAP_COLOR_BLEND * (rejection * LIGHTMAP_COLOR_REGEN + (1 - LIGHTMAP_COLOR_REGEN)) * mixTweak
	);
	
	FragOut0 = vec4(color, screenPos.z * 2 - 1);

#endif
}

/*
LIGHTMAP_COLOR_REJECTION
*/