

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

/* DRAWBUFFERS:4 */
void main() {
	vec3 screenPos = vec3(coord, getDepth(coord));

	vec4 prevProj    = reprojectScreen(screenPos);
	vec2 prevCoord   = prevProj.xy;
	const vec2 pixel = 1./vec2(16,9);

	vec3  prevCol   = gauss3x3(colortex4, prevProj.xy, pixel);
	float prevDepth = texture(colortex4, prevProj.xy).a;

	vec2 jitter = R2(frameCounter%1000) * pixel - (pixel * .5);
	vec3 color = gauss3x3Lod(colortex5, coord + jitter, pixel, 5) * 10;
	color = color / (color + 1.0);

	//float rejection = saturate( saturate(abs(linearizeDepthf(prevDepth, nearInverse) - linearizeDepthf(prevProj.z, nearInverse)) * -1.0 + 1) + float(saturate(prevProj.xy) == prevProj.xy));
	//float rejection = saturate(sqmag(saturate(prevProj.xy) - prevProj.xy) * -5 + 1) * (saturate(abs(linearizeDepthf(prevDepth, nearInverse) - linearizeDepthf(prevProj.z, nearInverse)) * -1.0 + 1) * .5 + .5);
	//float rejection = max(saturate(sqmag(saturate(prevProj.xy) - prevProj.xy) * -5 + 1), saturate( 1 - abs(linearizeDepthf(prevDepth, nearInverse) - linearizeDepthf(prevProj.z, nearInverse))));
	float rejection = max(saturate(sqmag(saturate(prevProj.xy) - prevProj.xy) * -4 + 1), saturate( abs(linearizeDepthf(prevDepth, nearInverse) - linearizeDepthf(prevProj.z, nearInverse)) * -0.5 + 1 ));
	color = mix(color, prevCol * rejection, 0.995 * (rejection * 0.01 + 0.99));

	//color = vec3( rejection);
	
	gl_FragData[0] = vec4(color, screenPos.z);
}