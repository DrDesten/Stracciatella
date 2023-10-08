#if ! defined INCLUDE_COMPOSITE3_FSH
#define INCLUDE_COMPOSITE3_FSH

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/composite_basics.glsl"
#include "/lib/transform.glsl"

vec2 coord = gl_FragCoord.xy * screenSizeInverse;
#if ! defined INCLUDE_UNIFORM_float_nearInverse
#define INCLUDE_UNIFORM_float_nearInverse
uniform float nearInverse; 
#endif

#if ! defined INCLUDE_UNIFORM_float_near
#define INCLUDE_UNIFORM_float_near
uniform float near; 
#endif

#if ! defined INCLUDE_UNIFORM_float_far
#define INCLUDE_UNIFORM_float_far
uniform float far; 
#endif

#if ! defined INCLUDE_UNIFORM_vec3_sunPosition
#define INCLUDE_UNIFORM_vec3_sunPosition
uniform vec3 sunPosition; 
#endif

#if ! defined INCLUDE_UNIFORM_float_frameTimeCounter
#define INCLUDE_UNIFORM_float_frameTimeCounter
uniform float frameTimeCounter; 
#endif
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
float lines(vec2 coord, vec2 dir) {
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
	float noiseStepFast = mod(floor(frameTimeCounter * 8), 5);
	float noiseStepSlow = mod(floor(frameTimeCounter * 3), 5);

	vec2 detailNoise = ( noise2(lineCoord / 4 + noiseStepFast) * 2 - 1 );
	vec2 coarseNoise = ( noise2(lineCoord / 8 + noiseStepSlow) * 2 - 1 );

	vec2 noiseCoord = coord + detailNoise * screenSizeInverse;

	// Get Depth Information

	float depth = getDepth(coord);

	float d  = getDepth(noiseCoord);
	float dn = getDepth(noiseCoord + vec2(0, screenSizeInverse.y));
	float ds = getDepth(noiseCoord - vec2(0, screenSizeInverse.y));
	float de = getDepth(noiseCoord + vec2(screenSizeInverse.x, 0));
	float dw = getDepth(noiseCoord - vec2(screenSizeInverse.x, 0));

	float maxDepthDiff =
		max( max(
			abs(d - dn),
			abs(d - ds)
		), max(
			abs(d - de),
			abs(d - dw)
		));
	bool safeNormals = maxDepthDiff > 1 / float(1 << 22);

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

	vec3 nn = normalsFromDepth(ldn, ld + (ld - ldn), lde, ldw);
	vec3 ns = normalsFromDepth(ld + (ld - lds), lds, lde, ldw);
	vec3 ne = normalsFromDepth(ldn, lds, lde, ld + (ld - lde));
	vec3 nw = normalsFromDepth(ldn, lds, ld + (ld - ldw), ldw);

	float normalDiff =
		abs(dot(n, nn)) +
		abs(dot(n, ns)) +
		abs(dot(n, ne)) +
		abs(dot(n, nw));
	normalDiff = normalDiff / 4;
	normalDiff = sqsq(normalDiff);
	normalDiff = 1 - normalDiff;

	// Get Position Information

	vec3 clipPos   = vec3(coord, depth) * 2 - 1;
	vec3 viewPos   = toView(clipPos);
	vec3 playerPos = toPlayer(viewPos);
	vec3 worldPos  = toWorld(playerPos);

	vec3 ppdx = dFdx(playerPos);
	vec3 ppdy = dFdy(playerPos);
	vec3 ppn  = normalize(cross(ppdx, ppdy));

	float       lineLength;
	const float lineLengthEpsilon    = 1e-2;
	vec3        playerLinePos        = playerPos;
	vec3        playerLineTangentPos = playerPos;

	// Pointing in y direction
	if (abs(ppn.y) > 0.99) { 
		lineLength              = worldPos.x;
		playerLinePos.x        += lineLengthEpsilon;
		playerLineTangentPos   += normalize(cross(ppn, vec3(1,0,0))) * lineLengthEpsilon;
	// Pointing in x direction
	} else if (abs(ppn.x) > 0.99) {
		lineLength              = worldPos.z; 
		playerLinePos.z        += lineLengthEpsilon;
		playerLineTangentPos   += normalize(cross(ppn, vec3(0,0,1))) * lineLengthEpsilon;
	// Pointing in z direction
	} else if (abs(ppn.z) > 0.99) {
		lineLength              = worldPos.x;
		playerLinePos.x        += lineLengthEpsilon;
		playerLineTangentPos   += normalize(cross(ppn, vec3(1,0,0))) * lineLengthEpsilon;
	} else {
		lineLength = -1;
	}

	vec3  screenLinePos        = backToClip(backToView(playerLinePos))        * .5 + .5;
	vec3  screenLineTangentPos = backToClip(backToView(playerLineTangentPos)) * .5 + .5;
	vec2  screenLineDir        = (screenLinePos.xy - coord)        * screenSize;
	vec2  screenLineTangent    = (screenLineTangentPos.xy - coord) * screenSize;

	float screenLineLength          = length(screenLineDir) / lineLengthEpsilon;
	float screenTangentAlign        = dot(normalize(screenLineDir), normalize(screenLineTangent));
	float correctedScreenLineLength = screenLineLength * sqrt( 1 - sq(acos(screenTangentAlign) / HALF_PI - 1) );

	// Process Color

	float brightness = luminance(color);
	color           /= brightness;
	color 			 = min(color, 1);

	color *= 0.75;
	color  = applySaturation(color, 1.5);

	int lineLevel = int(brightness * 8 + 0.5);

	// Effect

	switch (lineLevel) {
		case 0: 
			color *= float(int(gl_FragCoord.x) % 2);
		case 1: 
			color *= float(int(gl_FragCoord.y) % 2);
		/* case 2:
			color *= lines((lineCoord + detailNoise * 0.5) / 4, screenLineDir )  * 0.5 + 0.5; 
		case 3:
			color *= lines((lineCoord + detailNoise * 0.75) / 6, screenLineDir )  * 0.25  + 0.75; */
	}

	// Outline

	float outlineStrength = saturate( 1 - sqsq(ld/far * 2) );

	color *= vec3( 1 - depthDiff * outlineStrength );
	color *= vec3( 1 - normalDiff * outlineStrength * float(safeNormals) );

	float lineSpacing       = correctedScreenLineLength / 10;
	float hardLineSpacing   = exp2(floor(log2(lineSpacing)));
	float smoothLineSpacing = 2 * (lineSpacing - hardLineSpacing) / exp2(ceil(log2(lineSpacing)));

	const float lineWidth     = 25;
	const float lineSharpness = 3;
	float lmul = lineWidth * ( 1 + smoothLineSpacing ) * lineSharpness;
	float lsub = lmul - lineSharpness + (smoothLineSpacing / 2) * lineSharpness;

	float line1 = saturate(cos(lineLength * hardLineSpacing * PI) * lmul - lsub);
	float line2 = saturate(cos(lineLength * hardLineSpacing * PI + PI) * lmul - lsub);

	/* if (lineLength != -1 && depth < 1) {
		color *= 1 - line1;
		color *= 1 - line2 * saturate(smoothLineSpacing);
	} else {
		color *= lines((lineCoord + detailNoise * 0.75) / 6, PI / 4 )  * 0.25  + 0.75;
	}
 */
	FragOut0   = vec4(color, 1);
}


#endif