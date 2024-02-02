#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/core/kernels.glsl"
#include "/lib/composite_basics.glsl"

uniform sampler2D colortex6;

vec2 coord = gl_FragCoord.xy * screenSizeInverse * MC_RENDER_QUALITY;

vec4 textureBicubicComplexOpt(sampler2D sampler, vec2 coord, vec2 samplerSize, vec2 samplerSizeInverse) {
    vec4  totalData  = vec4(0);
    float totalWeight = 0;

    vec2 icoord   = coord * samplerSize;
    vec2 pixCoord = fract(icoord);

    for (int x = -1; x <= 2; x++) {
        for (int y = -1; y <= 2; y++) {

            vec4  sampleData = texelFetch(colortex0, ivec2(icoord) + ivec2(x,y), 0);
			float weight     = bell(pixCoord.x - x) * bell(pixCoord.y - y);

			totalData   += sampleData * weight;
			totalWeight += weight;
        
        }
    }

	return totalData / totalWeight;
}

vec4 textureBicubicSharp(sampler2D sampler, vec2 coord, vec2 samplerSize, vec2 pixelSize) {
    coord = coord * samplerSize - 0.5;

    vec2 fxy = fract(coord);
    coord -= fxy;

    vec4 xcubic = cubic(fxy.x);
    vec4 ycubic = cubic(fxy.y);

    vec4 c = coord.xxyy + vec2 (-0.5, +1.5).xyxy;

    vec4 s = vec4(xcubic.xz + xcubic.yw, ycubic.xz + ycubic.yw);
    vec4 offset = c + vec4 (xcubic.yw, ycubic.yw) / s;

    offset *= pixelSize.xxyy;

    vec4 sample0 = texture(sampler, offset.xz);
    vec4 sample1 = texture(sampler, offset.yz);
    vec4 sample2 = texture(sampler, offset.xw);
    vec4 sample3 = texture(sampler, offset.yw);

	vec4 average = (sample0 + sample1 + sample3 + sample3) * 0.25;

    float sx = s.x / (s.x + s.y);
    float sy = s.z / (s.z + s.w);

    return mix(
        mix(sample3, sample2, sx), 
        mix(sample1, sample0, sx)
    , sy);
}

struct FXAALumas {
	float n, s, w, e, m;
	float ne, nw, se, sw;
	float minimum, maximum, range;
};

float getLuma(vec2 coord) {
	return texelFetch(colortex0, ivec2(coord * screenSize * MC_RENDER_QUALITY), 0).a;
}

FXAALumas fillCross(vec2 coord, float size) {
	FXAALumas vals;
	vals.n = getLuma(coord + vec2(0, size * screenSizeInverse.y));
	vals.s = getLuma(coord - vec2(0, size * screenSizeInverse.y));
	vals.e = getLuma(coord + vec2(size * screenSizeInverse.x, 0));
	vals.w = getLuma(coord - vec2(size * screenSizeInverse.x, 0));
	vals.m = getLuma(coord);

	vals.maximum = max(max(max(max(vals.n, vals.s), vals.w), vals.e), vals.m);
	vals.minimum  = min(min(min(min(vals.n, vals.s), vals.w), vals.e), vals.m);
	vals.range = vals.maximum - vals.minimum;

	return vals;
}
/* 
vec3 FXAA311Upscale(vec2 coord, float size) {
	const float edgeThresholdMin = 0.0212;
	const float edgeThresholdMax = 0.0263;
	const float subpixelQuality  = 0.75;

	FXAALumas lumas = fillCross(coord, size);

	vec2 lrCoord = (floor((coord / size) * screenSize ) + 0.5) * screenSizeInverse * size;
	vec2 coordDiff = coord - lrCoord;
	
	if (lumas.range > max(edgeThresholdMin, lumas.maximum * edgeThresholdMax)) {
		// Get the remaining data points
		lumas.ne = getLuma(coord + screenSizeInverse * size);
		lumas.nw = getLuma(coord + vec2(-screenSizeInverse.x, screenSizeInverse.y) * size);
		lumas.sw = getLuma(coord - screenSizeInverse * size);
		lumas.se = getLuma(coord + vec2(screenSizeInverse.x, -screenSizeInverse.y) * size);

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
		float normalStepLength = isHorizontal ? screenSizeInverse.y * size : screenSizeInverse.x * size;

		float pixelEdgeLuma = 0.0;
		if (isEdge1) {
			normalStepLength = - normalStepLength;
			pixelEdgeLuma = 0.5 * (luma1 + lumas.m);
		} else {
			pixelEdgeLuma = 0.5 * (luma2 + lumas.m);
		}
		
		vec2 sampleCoord = lrCoord; // Move the sample coordinate to the edge
		if (isHorizontal) sampleCoord.y += normalStepLength * 0.5;
		else              sampleCoord.x += normalStepLength * 0.5;

		// Find Edge Lengths //////////////////////////////////////////////////////////////////////////
		
		vec2 traceStep = isHorizontal ? vec2(screenSizeInverse.x * size, 0.0) : vec2(0.0, screenSizeInverse.y * size);
		
		vec2 sco1 = sampleCoord;
		vec2 sco2 = sampleCoord;

		bool hit1 = false;
		bool hit2 = false;
		float lumaDiff1;
		float lumaDiff2;
		for(int i = 0; i < 9; i++) {
			if (!hit1) {
				sco1     -= traceStep * FXAAStepsUpscale[i];
				lumaDiff1 = getLuma(sco1) - pixelEdgeLuma;
				hit1      = abs(lumaDiff1) >= lumaEscapeDiff;
			}
			if (!hit2) {
				sco2     += traceStep * FXAAStepsUpscale[i];
				lumaDiff2 = getLuma(sco2) - pixelEdgeLuma;
				hit2      = abs(lumaDiff2) >= lumaEscapeDiff;
			}
			if (hit1 && hit2) break;
		}
		sco1 -= traceStep * FXAAStepsUpscale[9] * float(!hit1); // Faking an extra step
		sco2 += traceStep * FXAAStepsUpscale[9] * float(!hit2);
		
		float distance1 = isHorizontal ? (coord.x - sco1.x) : (coord.y - sco1.y);
		float distance2 = isHorizontal ? (sco2.x - coord.x) : (sco2.y - coord.y);

		float distanceToEdge = min(distance1, distance2);
		float edgeLength     = distance1 + distance2;

		//return vec3(distanceToEdge * (isHorizontal? screenSize.x : screenSize.y)) / 59;

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
 */
vec3 FXAA311Upscale(vec2 coord, float size) {
	const float edgeThresholdMin = 0.0212;
	const float edgeThresholdMax = 0.0263;
	const float subpixelQuality  = 0.75;

	const float renderScaleInverse = (1./MC_RENDER_QUALITY);
	const float renderScale        = MC_RENDER_QUALITY;

	FXAALumas lumas = fillCross(coord, renderScaleInverse);

	vec2 lrCoord = (floor( coord * screenSize * renderScaleInverse ) + 0.5) * screenSizeInverse * renderScale;
	vec2 coordDiff = coord - lrCoord;
	
	if (lumas.range > max(edgeThresholdMin, lumas.maximum * edgeThresholdMax)) {
		// Get the remaining data points
		lumas.ne = getLuma(coord + screenSizeInverse * size);
		lumas.nw = getLuma(coord + vec2(-screenSizeInverse.x, screenSizeInverse.y) * size);
		lumas.sw = getLuma(coord - screenSizeInverse * size);
		lumas.se = getLuma(coord + vec2(screenSizeInverse.x, -screenSizeInverse.y) * size);

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
		float normalStepLength = isHorizontal ? screenSizeInverse.y * size : screenSizeInverse.x * size;

		float pixelEdgeLuma = 0.0;
		if (isEdge1) {
			normalStepLength = - normalStepLength;
			pixelEdgeLuma = 0.5 * (luma1 + lumas.m);
		} else {
			pixelEdgeLuma = 0.5 * (luma2 + lumas.m);
		}
		
		vec2 sampleCoord = lrCoord; // Move the sample coordinate to the edge
		if (isHorizontal) sampleCoord.y += normalStepLength * 0.5;
		else              sampleCoord.x += normalStepLength * 0.5;

		// Find Edge Lengths //////////////////////////////////////////////////////////////////////////
		
		vec2 traceStep = isHorizontal ? vec2(screenSizeInverse.x * size, 0.0) : vec2(0.0, screenSizeInverse.y * size);
		
		vec2 sco1 = sampleCoord;
		vec2 sco2 = sampleCoord;

		bool hit1 = false;
		bool hit2 = false;
		float lumaDiff1;
		float lumaDiff2;
		for(int i = 0; i < 9; i++) {
			if (!hit1) {
				sco1     -= traceStep * FXAAStepsUpscale[i];
				lumaDiff1 = getLuma(sco1) - pixelEdgeLuma;
				hit1      = abs(lumaDiff1) >= lumaEscapeDiff;
			}
			if (!hit2) {
				sco2     += traceStep * FXAAStepsUpscale[i];
				lumaDiff2 = getLuma(sco2) - pixelEdgeLuma;
				hit2      = abs(lumaDiff2) >= lumaEscapeDiff;
			}
			if (hit1 && hit2) break;
		}
		sco1 -= traceStep * FXAAStepsUpscale[9] * float(!hit1); // Faking an extra step
		sco2 += traceStep * FXAAStepsUpscale[9] * float(!hit2);
		
		float distance1 = isHorizontal ? (coord.x - sco1.x) : (coord.y - sco1.y);
		float distance2 = isHorizontal ? (sco2.x - coord.x) : (sco2.y - coord.y);

		float distanceToEdge = min(distance1, distance2);
		float edgeLength     = distance1 + distance2;

		//return vec3(distanceToEdge * (isHorizontal? screenSize.x : screenSize.y)) / 59;

		float pixelOffset = 0.5 - distanceToEdge / edgeLength;
		
		bool isLumaCenterSmaller = lumas.m < pixelEdgeLuma;
		bool correctVariation    = ((distance1 < distance2 ? lumaDiff1 : lumaDiff2) < 0.0) != isLumaCenterSmaller; // Only apply to edges bulging in

		pixelOffset = correctVariation ? pixelOffset : 0.0;
		
		vec2 FXAACoord = coord;
		if (isHorizontal) FXAACoord.y += pixelOffset * normalStepLength;
		else              FXAACoord.x += pixelOffset * normalStepLength;

		return texelFetch(colortex0, ivec2(FXAACoord * screenSize), 0).rgb;
	}

	return texture(colortex0, coord).rgb;
}

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 FragOut0;
void main() {
#ifdef HQ_UPSCALING
	//vec3 color = textureBicubicComplexOpt(colortex0, coord * MC_RENDER_QUALITY, screenSize * (1./MC_RENDER_QUALITY), screenSizeInverse * MC_RENDER_QUALITY).rgb;
	vec3 color = textureBicubicSharp(colortex0, coord, screenSize * (1./MC_RENDER_QUALITY), screenSizeInverse * MC_RENDER_QUALITY).rgb;
#else
	vec3 color = getAlbedo(coord);

	color = color * 0.5 + texture(colortex6, coord / 81 + (2./3. + 2./9. + 2./27. + 2./81.)).rgb * 0.5;
#endif
	//color = FXAA311Upscale(coord, 2);
	FragOut0 = vec4(color, 1.0);
}

/*
#ifdef HQ_UPSCALING
dummy code (not even code lol)
#endif
*/