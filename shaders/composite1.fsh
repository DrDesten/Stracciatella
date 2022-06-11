

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/composite_basics.glsl"
#include "/lib/transform.glsl"

vec2 coord = gl_FragCoord.xy * vec2(1./16, 1./9);

const bool colortex0MipmapEnabled = true;
const bool colortex2MipmapEnabled = true;

uniform sampler2D colortex2;
uniform sampler2D colortex3;

uniform int frameCounter;

uniform float nearInverse;

vec3 sampleEmissive(vec2 coord, float lod) {
	vec3 col = textureLod(colortex0, coord.xy, lod).rgb;
	col /= max(0.05, maxc(col));
	return col * textureLod(colortex2, coord.xy, lod).x * saturate(1 - sqmag(saturate(coord.xy) - coord.xy));;
}

/* DRAWBUFFERS:3 */
void main() {
	vec3 screenPos = vec3(coord, getDepth(coord));
	vec2 prevCo = previousReproject(screenPos * 2 - 1).xy;
	prevCo += (R2(frameCounter) - 0.5) * vec2(.5/16, .5/9);
	vec3 color;

	for (int i = 0; i < 5; i++) {
		vec2 offs = R2((frameCounter%100) * 5 + i) * 2 - 1;
		offs *= .25;

		float w = exp(-dot(offs, offs) * 50);
		color += sampleEmissive(coord + offs, 2) * w;
	}

	color = color / ( maxc(color) + 0.1 );


	color = mix(color, texture(colortex3, prevCo).rgb, 0.995 * float(saturate(prevCo) == prevCo));
	
	gl_FragData[0] = vec4(color, 0);
}