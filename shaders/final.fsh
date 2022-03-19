#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/composite_basics.glsl"

vec2 coord = gl_FragCoord.xy * screenSizeInverse * MC_RENDER_QUALITY;

struct FXAALumas {
	float n, s, w, e, m;
	float ne, nw, se, sw;
	float lowest, highest, contrast;
};

float getLuma(vec2 coord) {
	return texture2D(colortex0, coord).a;
}

FXAALumas fillCross(vec2 coord) {
	FXAALumas vals;
	vals.n = getLuma(coord + vec2(0, screenSizeInverse.y));
	vals.s = getLuma(coord - vec2(0, screenSizeInverse.y));
	vals.e = getLuma(coord + vec2(screenSizeInverse.x, 0));
	vals.w = getLuma(coord - vec2(screenSizeInverse.x, 0));
	vals.m = getLuma(coord);

	vals.highest = max(max(max(max(vals.n, vals.s), vals.w), vals.e), vals.m);
	vals.lowest  = min(min(min(min(vals.n, vals.s), vals.w), vals.e), vals.m);
	vals.contrast = vals.highest - vals.lowest;

	return vals;
}

//FXAA 3.11 from http://blog.simonrodriguez.fr/articles/30-07-2016_implementing_fxaa.html (modified)
vec3 FXAA311(vec2 coord) {
	float edgeThresholdMin = 0.03125;
	float edgeThresholdMax = 0.125;
	float subpixelQuality  = 0.75;
	int   iterations = 10;

	FXAALumas lumas = fillCross(coord);
	
	if (lumas.contrast > max(edgeThresholdMin, lumas.highest * edgeThresholdMax)) {
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
		// By computing the gradient between the pixels, we can assume the higher contrast edge to be the actual edge
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
		for(int i = 0; i < iterations; i++) {
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
		
		float distance1 = isHorizontal ? (coord.x - sco1.x) : (coord.y - sco1.y); // This?
		float distance2 = isHorizontal ? (sco2.x - coord.x) : (sco2.y - coord.y);

		float distanceToEdge = min(distance1, distance2);
		float edgeLength     = distance1 + distance2;

		float pixelOffset = 0.5 - distanceToEdge / edgeLength;
		
		bool isLumaCenterSmaller = lumas.m < pixelEdgeLuma;
		bool correctVariation    = ((distance1 < distance2 ? lumaDiff1 : lumaDiff2) < 0.0) != isLumaCenterSmaller;

		pixelOffset = correctVariation ? pixelOffset : 0.0;
		
		/* float lumaAverage = (1.0 / 12.0) * (2.0 * (lumaDownUp + lumaLeftRight) + lumaLeftCorners + lumaRightCorners);
		float subPixelOffset1 = clamp(abs(lumaAverage - lumas.m) / lumas.contrast, 0.0, 1.0);
		float subPixelOffset2 = (-2.0 * subPixelOffset1 + 3.0) * subPixelOffset1 * subPixelOffset1;
		float subPixelOffsetFinal = subPixelOffset2 * subPixelOffset2 * subpixelQuality;

		pixelOffset = max(pixelOffset, subPixelOffsetFinal); */
		
		vec2 FXAACoord = coord;
		if (isHorizontal) FXAACoord.y += pixelOffset * normalStepLength;
		else              FXAACoord.x += pixelOffset * normalStepLength;

		return texture2D(colortex0, FXAACoord).rgb;
	}
	
	return texture2D(colortex0, coord).rgb;
}

/* DRAWBUFFERS:0 */
void main() {
	#ifdef BICUBIC_SAMPLING
	vec3 color = textureBicubic(colortex0, coord, screenSize, screenSizeInverse).rgb;
	#else
	vec3 color = getAlbedo(coord);
	#endif

	color = FXAA311(coord);

	gl_FragColor = vec4(color, 1.0);
}