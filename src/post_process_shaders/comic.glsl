#if defined PP_PREPASS

#include "noprepass.glsl"

#endif

#if defined PP_MAIN

#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/core/kernels.glsl"
#include "/lib/composite_basics.glsl"
#include "/core/transform.glsl"

vec2 coord = gl_FragCoord.xy * screenSizeInverse;

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

	vec3  color    = getAlbedo(coord);
	float depth    = getDepth(coord);
	vec4  lightmap = getLightmap(coord);

	// Process Color Information
	
	float brightness = luminance(color);
	color           /= brightness;
	color 			 = min(color, 1);

	color *= 0.8;
	color  = applySaturation(color, 1.5);

	// Noise

	vec2  lineCoord     = gl_FragCoord.xy;
	float noiseStepFast = mod(floor(frameTimeCounter * 8), 5);
	float noiseStepSlow = mod(floor(frameTimeCounter * 3), 5);

	vec2 detailNoise = ( noise2(lineCoord / 4 + noiseStepFast) * 2 - 1 );
	vec2 coarseNoise = ( noise2(lineCoord / 8 + noiseStepSlow) * 4 - 2 );

	vec2 noiseCoord       = coord + detailNoise * screenSizeInverse;
	vec2 noiseCoordCoarse = coord + coarseNoise * screenSizeInverse;

	// Get Depth Information

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

	vec3 screenPos = vec3(noiseCoordCoarse, depth);
	vec3 viewPos   = screenToView(screenPos);
	vec3 playerPos = toPlayer(viewPos);
	vec3 worldPos  = toWorld(playerPos);

	vec3 ppdx = dFdx(playerPos);
	vec3 ppdy = dFdy(playerPos);
	vec3 ppn  = normalize(cross(ppdx, ppdy));

	// World-Aligned Outlines

	const float worldLineGap          = 1./8;                 // 1/pixel_gap of world lines
	const float worldLineThickness    = 1 - 1 * worldLineGap; // Thickness factor

	const float worldLineSmudgeScale  = 0.2;
	const float worldLineSmudgeFactor = 0.5;

	vec3 worldLineSmudge           = noise3(worldPos * worldLineSmudgeScale) * 2 - 1;
	                               + noise3(worldPos * worldLineSmudgeScale * 0.25) * 8 - 4;
	vec3 worldLinePos = worldPos;
	worldLinePos.xz   = MAT2_ROT(PI/4, 1) * worldLinePos.xz;
	worldLinePos      = worldLinePos + worldLineSmudge * worldLineSmudgeFactor;

	// Rate change of world coordinates in screen apace
	vec3 worldLineDensity = vec3(
		length(vec2(dFdx(worldLinePos.x), dFdy(worldLinePos.x))) + 1e-10,
		length(vec2(dFdx(worldLinePos.y), dFdy(worldLinePos.y))) + 1e-10,
		length(vec2(dFdx(worldLinePos.z), dFdy(worldLinePos.z))) + 1e-10
	);
	// Scales adjusted for rendering lines of constant gap
	vec3  worldLineScaleSmooth    = worldLineGap / worldLineDensity;
	vec3  worldLineScale          = worldLineGap * exp2(-ceil(log2(worldLineDensity))); // Round to nearest power of two
	// Relative error introduced to line scales due to rounding, needed to correct thickness
	vec3 worldLineThicknessError = (worldLineScaleSmooth - worldLineScale) / worldLineScale;

	// World Lines
	vec3 worldLines = fstep(
		fract(worldLinePos * worldLineScale), 
		worldLineThickness + (1 - worldLineThickness) * 0.5 * worldLineThicknessError
	);

	// Select lines based on normal
	// Facing X => Y,Z
	// Facing Y => X,Z
	// Facing Z => X,Y
	worldLines =  1 - (1 - worldLines) * (1 - sq(ppn));
	if (depth == 1) worldLines = vec3(1);

	// Outline	

	float outlineStrength = saturate( 1 - sqsq(ld/far * 2) );

	color *= vec3( 1 - depthDiff * outlineStrength );
	color *= vec3( 1 - normalDiff * outlineStrength * float(safeNormals) );

	int lineLevel = int(brightness * 6 + 0.5);
	
	switch (lineLevel) {
		case 0: 
			color *= float(int(gl_FragCoord.x) % 2) * 0.5 + 0.5;
		case 1: 
			color *= float(int(gl_FragCoord.y) % 2) * 0.5 + 0.5;
		case 2:
			color *= worldLines.x * 0.25 + 0.75; 
		case 3:
			color *= worldLines.y * 0.25 + 0.75;
		case 4:
			color *= worldLines.z * 0.25 + 0.75;
	}

	//color = (worldLinePos - worldPos) * .5 + .5;
	//color = (worldLineBrightnessSmudge) * .5 + .5;

	FragOut0 = vec4(color, 1);
}

#endif