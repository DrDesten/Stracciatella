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


/* DRAWBUFFERS:0 */
void main() {
	#ifdef BICUBIC_SAMPLING
	vec3 color = textureBicubic(colortex0, coord, screenSize, screenSizeInverse).rgb;
	#else
	vec3 color = getAlbedo(coord);
	#endif


	FXAALumas l = fillCross(coord);
	if (l.contrast > max(0.03, 0.125 * l.highest)) { // Do FXAA
		// Get the remaining data points
		l.ne = getLuma(coord + screenSizeInverse);
		l.nw = getLuma(coord + vec2(-screenSizeInverse.x, screenSizeInverse.y));
		l.sw = getLuma(coord - screenSizeInverse);
		l.se = getLuma(coord + vec2(screenSizeInverse.x, -screenSizeInverse.y));

		// Calculate edge direction
		float horizontalComponent = abs((l.nw -2 * l.w + l.sw)) + 2 * abs((l.n -2 * l.m + l.s)) + abs((l.ne -2 * l.e + l.se));
		float verticalComponent   = abs((l.ne -2 * l.n + l.nw)) + 2 * abs((l.e -2 * l.m + l.w)) + abs((l.se -2 * l.s + l.sw));
		
		// Determine dominant edge direction (a more precise direction will be calculated later)
		bool isHorizontal = horizontalComponent > verticalComponent;

		// Using the edge direction, calculate on which side of the pixel the edge lies. 
		// By computing the gradient between the pixels, we can assume the higher contrast edge to be the actual edge
		float l1 = isHorizontal ? l.s : l.w;
		float l2 = isHorizontal ? l.n : l.e;
		float gradient1 = l1 - l.m; // edge is north (up) or east (right)
		float gradient2 = l2 - l.m; // edge is south (down) or west (left)

		bool isEdge1 = abs(gradient1) > abs(gradient2);

		// Calculate the pixel width normal to the edge (perpendicular)
		float normalStepSize = isHorizontal ? screenSizeInverse.y : screenSizeInverse.x;
		
		float edgeLuma;
		if (isEdge1) {
			normalStepSize = -normalStepSize; // If the edge is "lower" we have to invert the step size
			edgeLuma = (l1 + l.m) * .5;
		} else {
			edgeLuma = (l2 + l.m) * .5;
		}

		vec2 sampleCoord = coord; // Move the sample coordinate to the edge
		if (isHorizontal) sampleCoord.y += normalStepSize * 0.5;
		else              sampleCoord.x += normalStepSize * 0.5;

		// Find Edge Lengths //////////////////////////////////////////////////////////////////////////
		
		vec2 sco1 = sampleCoord;
		vec2 sco2 = sampleCoord;
		vec2 traceStep = isHorizontal ? vec2(screenSizeInverse.x, 0) : vec2(0, screenSizeInverse.y);

		float lumaEscapeDiff = 0.25 * max(abs(gradient1), abs(gradient2)); // If the luma difference is bigger than this, stop iterating

		bool hit1 = false;
		bool hit2 = false;
		float lumaDiff1;
		float lumaDiff2;
		for (int i = 0; i < 10; i++) {
			if (!hit1) {
				sco1 -= traceStep * FXAASteps[i];

				lumaDiff1 = getLuma(sco1) - edgeLuma;
				hit1 = abs(lumaDiff1) > lumaEscapeDiff;
			}
			if (!hit2) {
				sco2 += traceStep * FXAASteps[i];
				
				lumaDiff2 = getLuma(sco2) - edgeLuma;
				hit2 = abs(lumaDiff2) > lumaEscapeDiff;
			}
			if (hit1 && hit2) break;
		}

		float distance2 = isHorizontal ? (coord.x - sco1.x) : (coord.y - sco1.y);
		float distance1 = isHorizontal ? (sco2.x - coord.x) : (sco2.y - coord.y);

		float distToEdge = min(distance1, distance2);
		float edgeLength = distance1 + distance2;

		bool isLumaCenterSmaller = l.m < edgeLuma;
		bool isBumpBrighter = ((distance1 <= distance2 ? lumaDiff1 : lumaDiff2) > lumaEscapeDiff * 0.5);
		bool edgeBumpDirection = isBumpBrighter != isLumaCenterSmaller;

		float pixelOffset = 0.5 - distToEdge / edgeLength;

		pixelOffset = edgeBumpDirection ? pixelOffset : 0.0;

		vec2 FXAACoord = coord;
		if (isHorizontal) FXAACoord.y += pixelOffset * normalStepSize;
		else              FXAACoord.x += pixelOffset * normalStepSize;

		color = getAlbedo(FXAACoord);
		//color = vec3(isEdge1);
		//color = vec3(isHorizontal);
		//color = vec3(edgeBumpDirection);
		//color = vec3(distToEdge * 20);
		//color = vec3(pixelOffset * 500);
		//color = vec3(lumaDiff1 > 1e-10);
		//color = vec3(distance1 <= distance2);
		//color = vec3(horizontalComponent, verticalComponent, 0);
	}

	gl_FragColor = vec4(color, 1.0);
}