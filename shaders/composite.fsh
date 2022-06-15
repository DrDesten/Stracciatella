

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/composite_basics.glsl"
#include "/lib/transform.glsl"

vec2 coord = gl_FragCoord.xy * vec2(1./16, 1./9);

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

/* DRAWBUFFERS:4 */
layout(location = 0) out vec4 FragOut0;
void main() {
	vec3 screenPos = vec3(coord, getDepth(coord));

	vec4 prevProj    = reprojectScreen(screenPos);
	vec2 prevCoord   = prevProj.xy;
	const vec2 pixel = 1./vec2(16,9);

	vec3  prevCol   = gauss3x3(colortex4, prevProj.xy, pixel * 0.75);
	float prevDepth = texture(colortex4, prevProj.xy).a;

	float sampleLod = max(log2(mean(screenSize * pixel)), 0) * LIGHTMAP_COLOR_LOD_BIAS;
	vec2 jitter = R2(frameCounter%1000) * pixel - (pixel * .5);
	vec3 color = gauss3x3Lod(colortex5, coord + jitter, pixel, sampleLod) * 10;
	color = color / (color + 1.0);

	float age = maxc(prevCol); age = age / (age + 0.025);
	float sampleImportance = luminance(color.rgb);
	float mixTweak = age * (sampleImportance) + (1 - sampleImportance);
	mixTweak = mixTweak * (1 - LIGHTMAP_COLOR_FLICKER_RED) + LIGHTMAP_COLOR_FLICKER_RED;

	float rejection = max(saturate(sqmag(saturate(prevProj.xy) - prevProj.xy) * -4 + 1), saturate( abs(linearizeDepthf(prevDepth, nearInverse) - linearizeDepthf(prevProj.z, nearInverse)) * -0.5 + 1 ));
	color = mix(color, prevCol * rejection, LIGHTMAP_COLOR_BLEND * (rejection * LIGHTMAP_COLOR_REGEN + (1 - LIGHTMAP_COLOR_REGEN)) * mixTweak);
	
	FragOut0 = vec4(color, screenPos.z);
}