

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/composite_basics.glsl"
#include "/lib/transform.glsl"

vec2 coord = gl_FragCoord.xy * vec2(1./16, 1./9);

const bool colortex0MipmapEnabled = true;
const bool colortex2MipmapEnabled = true;

uniform sampler2D colortex2;
uniform sampler2D colortex4;

uniform int frameCounter;

uniform float nearInverse;

vec3 sampleEmissive(vec2 coord, float lod) {
	vec3 col = textureLod(colortex0, coord.xy, lod).rgb;
	col /= max(0.05, maxc(col));
	return col * textureLod(colortex2, coord.xy, lod).x * saturate(sqmag(saturate(coord.xy) - coord.xy) * -4 + 1);
}

vec3 gauss3x3(sampler2D tex, vec2 coord, vec2 pix) {
	return texture(tex, coord + .5 * pix.xy).rgb * .25 +
		   texture(tex, coord - .5 * pix.xy).rgb * .25 +
		   texture(tex, coord + .5 * vec2(pix.x, -pix.y)).rgb * .25 +
		   texture(tex, coord + .5 * vec2(-pix.x, pix.y)).rgb * .25;
}

/* DRAWBUFFERS:4 */
void main() {
	vec3 screenPos = vec3(coord, getDepth(coord));

	vec4 prevProj    = reprojectScreen(screenPos);
	vec2 prevCoord   = prevProj.xy;
	const vec2 pixel = vec2(1./16, 1./9);

	vec3 prevCol = gauss3x3(colortex4, coord, pixel);

	vec3 color;
	for (int i = 0; i < 10; i++) {
		vec2 offs = R2((frameCounter%100) + i * 100) * 2 - 1;
		offs *= pixel * 2;

		float w = exp(-dot(offs, offs) * 25);
		color += sampleEmissive(coord + offs, 4) * w;
	}

	color = color / ( maxc(color) + 0.1 );

	float rejection = saturate(sqmag(saturate(prevCoord) - prevCoord) * -5 + 1);
	rejection      *= saturate( 1 / ( abs(linearizeDepthf(prevProj.z, nearInverse) - linearizeDepthf(screenPos.z, nearInverse)) * 0.25 + 0.5) );
	color = mix(color, prevCol * rejection, 0.995 * (rejection * .25 + .75));
	
	gl_FragData[0] = vec4(color, 0);
}