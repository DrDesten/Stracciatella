#ifndef INCLUDE_COMPOSITE2_FSH
#define INCLUDE_COMPOSITE2_FSH

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/composite_basics.glsl"

vec2 coord = gl_FragCoord.xy * screenSizeInverse;

struct FXAALumas {
	float n, s, w, e, m;
	float ne, nw, se, sw;
	float minimum, maximum, range;
};

float getLuma(vec2 coord) {
	return texture(colortex0, coord).a;
}

FXAALumas fillCross(vec2 coord) {
	FXAALumas vals;
	vals.n = getLuma(coord + vec2(0, screenSizeInverse.y));
	vals.s = getLuma(coord - vec2(0, screenSizeInverse.y));
	vals.e = getLuma(coord + vec2(screenSizeInverse.x, 0));
	vals.w = getLuma(coord - vec2(screenSizeInverse.x, 0));
	vals.m = getLuma(coord);

	vals.maximum = max(max(max(max(vals.n, vals.s), vals.w), vals.e), vals.m);
	vals.minimum  = min(min(min(min(vals.n, vals.s), vals.w), vals.e), vals.m);
	vals.range = vals.maximum - vals.minimum;

	return vals;
}

//FXAA 3.11 from http://blog.simonrodriguez.fr/articles/30-07-2016_implementing_fxaa.html (modified)
vec3 FXAA311(vec2 coord) {
	float edgeThresholdMin = 0.0312;
	float edgeThresholdMax = 0.125;

	FXAALumas lumas = fillCross(coord);
	
	if (lumas.range > max(edgeThresholdMin, lumas.maximum * edgeThresholdMax)) {
		// Get the remaining data points
		lumas.ne = getLuma(coord + screenSizeInverse);
		lumas.nw = getLuma(coord + vec2(-screenSizeInverse.x, screenSizeInverse.y));
		lumas.sw = getLuma(coord - screenSizeInverse);
		lumas.se = getLuma(coord + vec2(screenSizeInverse.x, -screenSizeInverse.y));

		// Calculate edge direction
		float horizontalComponent = abs((lumas.nw -2 * lumas.w + lumas.sw)) + 2 * abs((lumas.n -2 * lumas.m + lumas.s)) + abs((lumas.ne -2 * lumas.e + lumas.se));
		float verticalComponent   = abs((lumas.ne -2 * lumas.n + lumas.nw)) + 2 * abs((lumas.e -2 * lumas.m + lumas.w)) + abs((lumas.se -2 * lumas.s + lumas.sw));
		
		// Determine dominant edge direction
		bool isHorizontal = (horizontalComponent >= verticalComponent);		
		
		// Using the edge direction, calculate on which side of the pixel the edge lies. 
		// By computing the gradient between the pixels, we can assume the higher range edge to be the actual edge
		float luma1 = isHorizontal ? lumas.s : lumas.w;
		float luma2 = isHorizontal ? lumas.n : lumas.e;
		float gradient1 = luma1 - lumas.m;
		float gradient2 = luma2 - lumas.m;
		
		bool  isEdge1 = abs(gradient1) > abs(gradient2);
		float lumaEscapeDiff = 0.25 * max(abs(gradient1), abs(gradient2));
		
		// Calculate the pixel width normal to the edge (perpendicular)
		float normalStepLength = isHorizontal ? screenSizeInverse.y : screenSizeInverse.x;

		float pixelEdgeLuma = 0.0;
		if (isEdge1) {
			normalStepLength = - normalStepLength;
			pixelEdgeLuma = 0.5 * (luma1 + lumas.m);
		} else {
			pixelEdgeLuma = 0.5 * (luma2 + lumas.m);
		}
		
		vec2 sampleCoord = coord; // Move the sample coordinate to the edge
		if (isHorizontal) sampleCoord.y += normalStepLength * 0.5;
		else              sampleCoord.x += normalStepLength * 0.5;

		// Find Edge Lengths //////////////////////////////////////////////////////////////////////////
		
		vec2 traceStep = isHorizontal ? vec2(screenSizeInverse.x, 0.0) : vec2(0.0, screenSizeInverse.y);
		
		vec2 sco1 = sampleCoord;
		vec2 sco2 = sampleCoord;

		bool hit1 = false;
		bool hit2 = false;
		float lumaDiff1;
		float lumaDiff2;
		for(int i = 0; i < 9; i++) {
			if (!hit1) {
				sco1     -= traceStep * FXAASteps[i];
				lumaDiff1 = getLuma(sco1) - pixelEdgeLuma;
				hit1      = abs(lumaDiff1) >= lumaEscapeDiff;
			}
			if (!hit2) {
				sco2     += traceStep * FXAASteps[i];
				lumaDiff2 = getLuma(sco2) - pixelEdgeLuma;
				hit2      = abs(lumaDiff2) >= lumaEscapeDiff;
			}
			if (hit1 && hit2) break;
		}
		sco1 -= traceStep * FXAASteps[9] * float(!hit1); // Faking an extra step
		sco2 += traceStep * FXAASteps[9] * float(!hit2);
		
		float distance1 = isHorizontal ? (coord.x - sco1.x) : (coord.y - sco1.y);
		float distance2 = isHorizontal ? (sco2.x - coord.x) : (sco2.y - coord.y);

		float distanceToEdge = min(distance1, distance2);
		float edgeLength     = distance1 + distance2;

		float pixelOffset = 0.5 - distanceToEdge / edgeLength;
		
		bool isLumaCenterSmaller = lumas.m < pixelEdgeLuma;
		bool correctVariation    = ((distance1 < distance2 ? lumaDiff1 : lumaDiff2) < 0.0) != isLumaCenterSmaller; // Only apply to edges bulging in

		pixelOffset = correctVariation ? pixelOffset : 0.0;
		
		vec2 FXAACoord = coord;
		if (isHorizontal) FXAACoord.y += pixelOffset * normalStepLength;
		else              FXAACoord.x += pixelOffset * normalStepLength;

		return texture(colortex0, FXAACoord).rgb;
	}

	return texture(colortex0, coord).rgb;
}
vec3 FXAA311HQ(vec2 coord) {
	const float edgeThresholdMin = 0.0312;
	const float edgeThresholdMax = 0.0363;
	const float subpixelQuality  = 0.75;

	FXAALumas lumas = fillCross(coord);
	
	if (lumas.range > max(edgeThresholdMin, lumas.maximum * edgeThresholdMax)) {
		// Get the remaining data points
		lumas.ne = getLuma(coord + screenSizeInverse);
		lumas.nw = getLuma(coord + vec2(-screenSizeInverse.x, screenSizeInverse.y));
		lumas.sw = getLuma(coord - screenSizeInverse);
		lumas.se = getLuma(coord + vec2(screenSizeInverse.x, -screenSizeInverse.y));

		float lumaWCorners = lumas.nw + lumas.sw;
		float lumaECorners = lumas.ne + lumas.se;

		// Calculate edge direction
		float horizontalComponent = abs((-2 * lumas.w + lumaWCorners)) + 2 * abs((lumas.n -2 * lumas.m + lumas.s)) + abs((-2 * lumas.e + lumaECorners));
		float verticalComponent   = abs((lumas.ne -2 * lumas.n + lumas.nw)) + 2 * abs((lumas.e -2 * lumas.m + lumas.w)) + abs((lumas.se -2 * lumas.s + lumas.sw));
		
		// Determine dominant edge direction
		bool isHorizontal = (horizontalComponent >= verticalComponent);		
		
		// Using the edge direction, calculate on which side of the pixel the edge lies. 
		// By computing the gradient between the pixels, we can assume the higher range edge to be the actual edge
		float luma1 = isHorizontal ? lumas.s : lumas.w;
		float luma2 = isHorizontal ? lumas.n : lumas.e;
		float gradient1 = luma1 - lumas.m;
		float gradient2 = luma2 - lumas.m;
		
		bool  isEdge1 = abs(gradient1) > abs(gradient2);
		float lumaEscapeDiff = 0.25 * max(abs(gradient1), abs(gradient2));
		
		// Calculate the pixel width normal to the edge (perpendicular)
		float normalStepLength = isHorizontal ? screenSizeInverse.y : screenSizeInverse.x;

		float pixelEdgeLuma = 0.0;
		if (isEdge1) {
			normalStepLength = - normalStepLength;
			pixelEdgeLuma = 0.5 * (luma1 + lumas.m);
		} else {
			pixelEdgeLuma = 0.5 * (luma2 + lumas.m);
		}
		
		vec2 sampleCoord = coord; // Move the sample coordinate to the edge
		if (isHorizontal) sampleCoord.y += normalStepLength * 0.5;
		else              sampleCoord.x += normalStepLength * 0.5;

		// Find Edge Lengths //////////////////////////////////////////////////////////////////////////
		
		vec2 traceStep = isHorizontal ? vec2(screenSizeInverse.x, 0.0) : vec2(0.0, screenSizeInverse.y);
		
		vec2 sco1 = sampleCoord;
		vec2 sco2 = sampleCoord;

		bool hit1 = false;
		bool hit2 = false;
		float lumaDiff1;
		float lumaDiff2;
		for(int i = 0; i < 9; i++) {
			if (!hit1) {
				sco1     -= traceStep * FXAASteps[i];
				lumaDiff1 = getLuma(sco1) - pixelEdgeLuma;
				hit1      = abs(lumaDiff1) >= lumaEscapeDiff;
			}
			if (!hit2) {
				sco2     += traceStep * FXAASteps[i];
				lumaDiff2 = getLuma(sco2) - pixelEdgeLuma;
				hit2      = abs(lumaDiff2) >= lumaEscapeDiff;
			}
			if (hit1 && hit2) break;
		}
		sco1 -= traceStep * FXAASteps[9] * float(!hit1); // Faking an extra step
		sco2 += traceStep * FXAASteps[9] * float(!hit2);
		
		float distance1 = isHorizontal ? (coord.x - sco1.x) : (coord.y - sco1.y);
		float distance2 = isHorizontal ? (sco2.x - coord.x) : (sco2.y - coord.y);

		float distanceToEdge = min(distance1, distance2);
		float edgeLength     = distance1 + distance2;

		//return vec3(distanceToEdge * (isHorizontal? screenSize.x : screenSize.y)) / 59;

		float pixelOffset = 0.5 - distanceToEdge / edgeLength;
		
		bool isLumaCenterSmaller = lumas.m < pixelEdgeLuma;
		bool correctVariation    = ((distance1 < distance2 ? lumaDiff1 : lumaDiff2) < 0.0) != isLumaCenterSmaller; // Only apply to edges bulging in

		pixelOffset = correctVariation ? pixelOffset : 0.0;

		float lumaAverage     = (1./12.) * ((lumaECorners + lumaWCorners) + 2 * (lumas.n + lumas.s + lumas.e + lumas.w));
		float subPixelOffset1 = ( abs(lumaAverage - lumas.m) / lumas.range );
		float subPixelOffset2 = (-2.0 * subPixelOffset1 + 3.0) * subPixelOffset1 * subPixelOffset1;
		float subPixelOffset  = subPixelOffset2 * subPixelOffset2 * subpixelQuality;

		pixelOffset = max(pixelOffset, subPixelOffset);
		
		vec2 FXAACoord = coord;
		if (isHorizontal) FXAACoord.y += pixelOffset * normalStepLength;
		else              FXAACoord.x += pixelOffset * normalStepLength;

		return texture(colortex0, FXAACoord).rgb;
	}

	return texture(colortex0, coord).rgb;
}

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 FragOut0;
void main() {
	vec3 color = FXAA311HQ(coord);
	FragOut0   = vec4(color, 1.0);
}

/*
#ifdef FXAA
dummy code (not even code lol)
#endif
*/


#endif