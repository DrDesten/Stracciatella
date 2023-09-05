#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/composite_basics.glsl"

vec2 coord = gl_FragCoord.xy * screenSizeInverse;

uniform float nearInverse;
uniform float near;
uniform float far;

uniform vec3 sunPosition;

uniform float frameTimeCounter;

vec3 normalsFromDepth(float linearDepth) {
	float dx = dFdx(linearDepth) * screenSize.x;
	float dy = dFdy(linearDepth) * screenSize.y;
	return normalize(vec3(dx, dy, -1));
}

vec3 normalsFromDepth(float ldn, float lds, float lde, float ldw) {
	float dx = (lde - ldw) * screenSize.x;
	float dy = (ldn - lds) * screenSize.y;
	return normalize(vec3(dx, dy, -1));
}

float lines(vec2 coord, float angle) {
	vec2  dir   = vec2(sin(angle), cos(angle));
	float len   = dot(coord, dir);
	float lines = sin(len * PI);

	lines = saturate(lines * 2 - 1);
	return 1 - lines;
}

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 FragOut0;
void main() {

	// Get Color Information
	
	vec3  color = getAlbedo(coord);

	// Noise

	vec2  lineCoord = gl_FragCoord.xy;
	float noiseStep = mod(floor(frameTimeCounter * 6), 5);
	vec2  lineNoise = ( noise2(lineCoord / 4 + noiseStep) * 2 - 1 );

	coord += lineNoise * screenSizeInverse;

	// Get Depth Information

	float d  = getDepth(coord);
	float dn = getDepth(coord + vec2(0, screenSizeInverse.y));
	float ds = getDepth(coord - vec2(0, screenSizeInverse.y));
	float de = getDepth(coord + vec2(screenSizeInverse.x, 0));
	float dw = getDepth(coord - vec2(screenSizeInverse.x, 0));

	float maxDepthDiff =
		max( max(
			abs(d - dn),
			abs(d - ds)
		), max(
			abs(d - de),
			abs(d - dw)
		));
	bool safeNormals = maxDepthDiff > 1 / float(1 << 23);

	float ld  = linearizeDepth(d, near, far);
	float ldn = linearizeDepth(dn, near, far);
	float lds = linearizeDepth(ds, near, far);
	float lde = linearizeDepth(de, near, far);
	float ldw = linearizeDepth(dw, near, far);

	float depthDiff =
		abs(ld - ldn) +
		abs(ld - lds) +
		abs(ld - lde) +
		abs(ld - ldw);
	depthDiff = depthDiff / ( depthDiff + 1 );
	depthDiff = sqsq(depthDiff) * 0.75;

	// Get Normal Information

	vec3 n  = normalsFromDepth(ldn, lds, lde, ldw);
	vec3 nn = normalsFromDepth(ldn, ld,  lde, ldw);
	vec3 ns = normalsFromDepth(ld,  lds, lde, ldw);
	vec3 ne = normalsFromDepth(ldn, lds, lde, ld);
	vec3 nw = normalsFromDepth(ldn, lds, ld,  ldw);

	float normalDiff =
		abs(dot(n, nn)) +
		abs(dot(n, ns)) +
		abs(dot(n, ne)) +
		abs(dot(n, nw));
	normalDiff = normalDiff / 4;
	normalDiff = sqsq(normalDiff);
	normalDiff = 1 - normalDiff;

	// Process Color

	float brightness = luminance(color);
	color           /= brightness;
	color 			 = min(color, 1);

	color *= 0.75;
	color  = applySaturation(color, 1.5);

	int lineLevel = int(brightness * 6 + 0.5);

	// Effect

	switch (lineLevel) {
		case 0: 
			color *= lines(lineCoord, 0);
		case 1:
			color *= lines((lineCoord + lineNoise * 0.5) / 2, TWO_PI / 4 )  * 0.75 + 0.25;
		case 2:
			color *= lines((lineCoord + lineNoise * 0.75) / 4, TWO_PI / 8 )  * 0.5  + 0.5;
		case 3:
			color *= lines((lineCoord + lineNoise) / 6, TWO_PI / 16 ) * 0.25 + 0.75;
	}

	// Outline

	float outlineStrength = saturate( 1 - sqsq(ld/far * 2) );

	color *= vec3( 1 - depthDiff * outlineStrength );
	color *= vec3( 1 - normalDiff * outlineStrength * float(safeNormals) );

	FragOut0   = vec4(color, 1);
}
