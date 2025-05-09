
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/lib/composite_basics.glsl"
#include "/core/transform.glsl"

/*
// Post Process Shaders
const int colortex7Format = RGBA16F;
*/

vec2  coord  = gl_FragCoord.xy * screenSizeInverse;
ivec2 icoord = ivec2(gl_FragCoord.xy);

uniform float nearInverse;
uniform float near;
uniform float far;

#if defined PP_PREPASS

/* DRAWBUFFERS:7 */
layout(location = 0) out vec4 FragOut0;
void main() {
	float depth = 0;

	#define S(dx, dy) depth += texelFetchOffset(depthtex0, icoord, 0, ivec2(dx, dy)).x

	#if 0

	// 7x7
	S(-3,-3);S(-2,-3);S(-1,-3);S(0,-3);S(1,-3);S(2,-3);S(3,-3);
	S(-3,-2);S(-2,-2);S(-1,-2);S(0,-2);S(1,-2);S(2,-2);S(3,-2);
	S(-3,-1);S(-2,-1);S(-1,-1);S(0,-1);S(1,-1);S(2,-1);S(3,-1);
	S(-3, 0);S(-2, 0);S(-1, 0);S(0, 0);S(1, 0);S(2, 0);S(3, 0);
	S(-3, 1);S(-2, 1);S(-1, 1);S(0, 1);S(1, 1);S(2, 1);S(3, 1);
	S(-3, 2);S(-2, 2);S(-1, 2);S(0, 2);S(1, 2);S(2, 2);S(3, 2);
	S(-3, 3);S(-2, 3);S(-1, 3);S(0, 3);S(1, 3);S(2, 3);S(3, 3);
	depth /= 49;

	#else

	// 5x5
	S(-2, -2); S(-1, -2); S( 0, -2); S( 1, -2); S( 2, -2);
	S(-2, -1); S(-1, -1); S( 0, -1); S( 1, -1); S( 2, -1);
	S(-2,  0); S(-1,  0); S( 0,  0); S( 1,  0); S( 2,  0);
	S(-2,  1); S(-1,  1); S( 0,  1); S( 1,  1); S( 2,  1);
	S(-2,  2); S(-1,  2); S( 0,  2); S( 1,  2); S( 2,  2);
	depth /= 25;

	#endif

	#undef S

	float linearDepth = linearizeDepth(depth, near, far);

	FragOut0 = vec4(linearDepth, 0, 0, 0);
}


#endif

#if defined PP_MAIN

uniform sampler2D colortex7;
const bool colortex0MipmapEnabled = true;
const bool colortex7MipmapEnabled = true;
vec4 getBuffer(vec2 coord) { return texture(colortex7, coord); }
vec4 getBufferLod(vec2 coord, float lod) { return textureLod(colortex7, coord, lod); }


uniform vec3 sunPosition;

uniform float frameTimeCounter;


uniform sampler2D colortex1;
vec4 getLightmap(vec2 coord) {
    return vec2x16to4(texture(colortex1, coord).xy);
}

// 4x4 Lanczos
vec4 textureLanczos(sampler2D tex, ivec2 icoord, vec2 subpixel, int lod) {
    ivec2 texSize = textureSize(tex, lod);
    
    if (icoord.x < 0 || icoord.y < 0 || icoord.x >= texSize.x || icoord.y >= texSize.y) {
        return texelFetch(tex, icoord, lod);
    }
    
    vec4  result    = vec4(0.0);
    float weightSum = 0.0;
    
    // Compute weights
    float wx[4], wy[4];
    wx[0] = lanczos2(-1 - subpixel.x);
    wx[1] = lanczos2(+0 - subpixel.x);
    wx[2] = lanczos2(+1 - subpixel.x);
    wx[3] = lanczos2(+2 - subpixel.x);
    wy[0] = lanczos2(-1 - subpixel.y);
    wy[1] = lanczos2(+0 - subpixel.y);
    wy[2] = lanczos2(+1 - subpixel.y);
    wy[3] = lanczos2(+2 - subpixel.y);
    
    // Sampling offsets relative to icoord
    #define L(ox, oy) \
        if (icoord.x + ox > 0 && icoord.y + oy > 0) { \
            float weight = wx[ox+1] * wy[oy+1]; \
            result      += texelFetchOffset(tex, icoord, lod, ivec2(ox-1, oy-1)) * weight; \
            weightSum   += weight; \
        }
    
    // 16 samples for 4x4 grid centered around icoord
    L(-1, -1); L( 0, -1); L( 1, -1); L( 2, -1);
	L(-1,  0); L( 0,  0); L( 1,  0); L( 2,  0);
	L(-1,  1); L( 0,  1); L( 1,  1); L( 2,  1);
	L(-1,  2); L( 0,  2); L( 1,  2); L( 2,  2);
    
    #undef L
    
    return result / weightSum;
}

// Function that matches textureLod signature but uses Lanczos filtering
vec4 textureLanczosLod(sampler2D tex, vec2 coord, int lod) {
    ivec2 texSize  = textureSize(tex, lod);
    vec2  texCoord = coord * vec2(texSize);
    ivec2 icoord   = ivec2(texCoord);
    vec2  subpixel = texCoord - vec2(icoord);
    return textureLanczos(tex, icoord, subpixel, lod);
}

// Helper function for cubic filter weight calculation (modified for 3-tap)
float cubicFilter3(float x) {
    float x2 = x * x;
    
    // Modified cubic coefficients for 3-tap (still C1 continuous)
    if (x < 0.0) x = -x;
    
    if (x < 1.0)
        return (1.0 - 2.0 * x2 + x2 * x);
    else if (x < 1.5)
        return (4.0 - 8.0 * x + 5.0 * x2 - x2 * x) / 3.0;
    else
        return 0.0;
}

// 3-tap bicubic sampler
vec4 textureBicubicLod(sampler2D tex, vec2 coord, int lod) {
    // Get texture size at the specified LOD level
    ivec2 texSize = textureSize(tex, lod);
    
    // Convert normalized [0,1] coordinates to texture space
    vec2 texCoord = coord * vec2(texSize);
    
    // Get integer coordinate and subpixel offset
    ivec2 icoord = ivec2(floor(texCoord));
    vec2 fract = texCoord - vec2(icoord);
    
    // Calculate filter weights for x and y
    vec3 wx = vec3(
        cubicFilter3(1.0 + fract.x),
        cubicFilter3(fract.x),
        cubicFilter3(1.0 - fract.x)
    );
    
    vec3 wy = vec3(
        cubicFilter3(1.0 + fract.y),
        cubicFilter3(fract.y),
        cubicFilter3(1.0 - fract.y)
    );
    
    // Normalize weights
    wx /= (wx.x + wx.y + wx.z);
    wy /= (wy.x + wy.y + wy.z);
    
    // Initialize result
    vec4 result = vec4(0.0);
    
    // 3x3 sampling grid
    #define B(dx, dy) \
        texelFetchOffset(tex, icoord, lod, ivec2(dx-1, dy-1)) * wx[dx] * wy[dy]
    
    // Sample the 9 texels with appropriate weights
    result += B(0, 0);
    result += B(0, 1);
    result += B(0, 2);
    
    result += B(1, 0);
    result += B(1, 1);
    result += B(1, 2);
    
    result += B(2, 0);
    result += B(2, 1);
    result += B(2, 2);
    
    #undef B
    
    return result;
}

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 FragOut0;
void main() {
	vec3 baseColor  = getAlbedo(coord);
	vec4 bufferData = getBuffer(coord);
	
	const int iter   = 5;
	float     weight = 0;
	float     ldepth  = 0;
	for (int lod = 1; lod < iter; lod++) {
		float w  = lod;
		ldepth  += textureBicubicLod(colortex7, coord, lod).x * w;
		weight  += w;
	}
	ldepth /= weight;

	float depth     = linearizeDepthInverse(ldepth, near, far);
	vec3  screenPos = vec3(coord, depth);
	vec3  viewPos   = screenToView(screenPos);
	vec3  playerPos = toPlayer(viewPos);
	vec3  worldPos  = toWorld(playerPos);

	vec3 ppdx = dFdx(playerPos);
	vec3 ppdy = dFdy(playerPos);
	vec3 ppn  = normalize(cross(ppdx, ppdy));

	vec3 color = vec3(ppn) * .5 + .5;

	//color = vec3(ldepth * 0.01);

	FragOut0   = vec4(color, 1);
}

#endif