#version 120

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/composite_basics.glsl"

vec2 coord = gl_FragCoord.xy * screenSizeInverse * MC_RENDER_QUALITY;

/* uniform sampler2D colortex1;

vec3 FXAAConsole(vec2 coord, sampler2D lumatex, sampler2D colortex) {

	vec2  po = screenSizeInverse * (0.5 / MC_RENDER_QUALITY); //pixelOffset

	float luma_m  = texture2D(lumatex, coord).r;
	float luma_nw = texture2D(lumatex, coord + vec2(-po.x,  po.y)).r;
	float luma_ne = texture2D(lumatex, coord + vec2( po.x,  po.y)).r;
	float luma_sw = texture2D(lumatex, coord + vec2(-po.x, -po.y)).r;
	float luma_se = texture2D(lumatex, coord + vec2( po.x, -po.y)).r;

	float maxLuma = max(max(luma_nw, luma_ne), max(luma_sw, luma_se));
	float minLuma = min(min(luma_nw, luma_ne), min(luma_sw, luma_se));

	if (maxLuma - minLuma < 0.05) { return texture2D(colortex, coord).rgb; } // Early Exit

	vec2 edgeDir;
	edgeDir.x = (luma_sw+luma_se) - (luma_nw+luma_ne) + 0.01;
	edgeDir.y = (luma_nw+luma_sw) - (luma_ne+luma_se);
	edgeDir   = normalize(edgeDir);

	return vec3(edgeDir * 0.5 + 0.5, 0);
} */

/* DRAWBUFFERS:0 */
void main() {
	vec3 color = getAlbedo(coord);

	gl_FragColor = vec4(color, 1.0);
}