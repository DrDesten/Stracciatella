#define GAMMA 2.0

const float TWO_PI  = 6.28318530717958647692;
const float PI      = 3.14159265358979323846;
const float HALF_PI = 1.57079632679489661923;
const float INV_PI  = 0.31830988618379067153;
const float PHI     = 1.61803398874989484820;


////////////////////////////////////////////////////////////////////////
// General Functions

bool closeTo(float a, float b, float epsilon) {
    return abs(a-b) < epsilon;
}

float fstep(float edge, float x) { // Fast step() function with no branching
    return clamp((x - edge) * 1e35, 0, 1);
}

float sum(vec2 v) {
    return v.x + v.y;
}
float sum(vec3 v) {
    return v.x + v.y + v.z;
}
float sum(vec4 v) {
    return (v.x + v.y) + (v.z + v.w);
}

float mean(vec2 vector) {
    return (vector.x + vector.y) * 0.5;
}
float mean(vec3 vector) {
    return (vector.x + vector.y + vector.z) * 0.333333333333;
}
float mean(vec4 vector) {
    return ((vector.x + vector.y) + (vector.z + vector.w)) * 0.25;
}

vec2 midpoint(vec2 v1, vec2 v2) {
    return (v1 + v2) * 0.5;
}
vec3 midpoint(vec3 v1, vec3 v2) {
    return (v1 + v2) * 0.5;
}
vec4 midpoint(vec4 v1, vec4 v2) {
    return (v1 + v2) * 0.5;
}

float sqmag(vec2 v) {
    return dot(v, v);
}
float sqmag(vec3 v) {
    return dot(v, v);
}
float sqmag(vec4 v) {
    return dot(v, v);
}

float manhattan(vec2 v) {
    return abs(v.x) + abs(v.y);
}
float manhattan(vec3 v) {
    return abs(v.x) + abs(v.y) + abs(v.z);
}
float manhattan(vec4 v) {
    return (abs(v.x) + abs(v.y)) + (abs(v.z) + abs(v.w));
}

float sq(float x) { // Square
    return x * x;
}
vec2 sq(vec2 x) {
    return x * x;
}
vec3 sq(vec3 x) {
    return x * x;
}
vec4 sq(vec4 x) {
    return x * x;
}

float ssq(float x) { // Signed Square
    return x * abs(x);
}
vec2 ssq(vec2 x) {
    return x * abs(x);
}
vec3 ssq(vec3 x) {
    return x * abs(x);
}
vec4 ssq(vec4 x) {
    return x * abs(x);
}

float cb(float x) { // Cube
    return x * x * x;
}
vec2 cb(vec2 x) {
    return x * x * x;
}
vec3 cb(vec3 x) {
    return x * x * x;
}
vec4 cb(vec4 x) {
    return x * x * x;
}

float logn(float base, float res) { // Log base n
    return log2(res) / log2(base);
}

float saturate(float a) {
    return clamp(a, 0.0, 1.0);
}
vec2 saturate(vec2 a) {
    return clamp(a, 0.0, 1.0);
}
vec3 saturate(vec3 a) {
    return clamp(a, 0.0, 1.0);
}
vec4 saturate(vec4 a) {
    return clamp(a, 0.0, 1.0);
}

float angleBetween(vec3 v1, vec3 v2) {
    return acos(dot(normalize(v1), normalize(v2)));
}

float asinf(float x) { // s(x) = x + x³/8 + x^5/5
    float x2  = x*x;
    float x4  = x2*x2;
    return x + (x2 * x * .125) + (x4 * x * .2);
}
float acosf(float x) {
    return HALF_PI - asinf(x);
}

float smootherstep(float x) { // Second derivative zero as well
    return saturate( cb(x) * (x * (6. * x - 15.) + 10.) );
}
float smootherstep(float edge0, float edge1, float x) {
    x = saturate((x - edge0) * (1. / (edge1 - edge0)));
    return cb(x) * (x * (6. * x - 15.) + 10.);
}

////////////////////////////////////////////////////////////////////////
// Randomization and Dither Patterns

float Bayer2(vec2 a) {
    a = floor(a);
    return fract(a.x * .5 + a.y * a.y * .75);
}
#define Bayer4(a)   (Bayer2 (0.5 * (a)) * 0.25 + Bayer2(a))
#define Bayer8(a)   (Bayer4 (0.5 * (a)) * 0.25 + Bayer2(a))
#define Bayer16(a)  (Bayer8 (0.5 * (a)) * 0.25 + Bayer2(a))
#define Bayer32(a)  (Bayer16(0.5 * (a)) * 0.25 + Bayer2(a))
#define Bayer64(a)  (Bayer32(0.5 * (a)) * 0.25 + Bayer2(a))


float rand(float x) {
    return fract(sin(x * 12.9898) * 4375.5453123);
}
float rand(vec2 x) {
    return fract(sin(x.x * 12.9898 + x.y * 78.233) * 4375.5453);
}
float rand11(float x) {
    return rand(x) * 2 - 1;
}
float rand11(vec2 x) {
    return rand(x) * 2 - 1;
}

vec2 N22(vec2 x) {
    return vec2(rand(x - 5), rand(x + 5));
}

float noise(vec2 x) {
    vec2 i = floor(x);
    vec2 f = fract(x);

	// Four corners in 2D of a tile
	float a = rand(i);
    float b = rand(i + vec2(1.0, 0.0));
    float c = rand(i + vec2(0.0, 1.0));
    float d = rand(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}
float noise(float x) {
    float i = floor(x);
    float f = fract(x);

	// Two connecting points
	float a = rand(i);
    float b = rand(i + 1.0);

	return smoothstep(a, b, f);
}

float fbm(vec2 x, int n) {
	float v = 0.0;
	float a = 0.5;
	vec2 shift = vec2(100);

	// Rotate to reduce axial bias
    const mat2 rot = mat2(cos(0.5), sin(0.5), -sin(0.5), cos(0.50));

	for (int i = 0; i < n; ++i) {
		v += a * noise(x);
		x  = rot * x * 2.0 + shift;
		a *= 0.5;
	}
	return v;
}

float fbm(vec2 x, int n, float scale, float falloff) {
	float v = 0.0;
	float a = 0.5;
	vec2 shift = vec2(100);

	// Rotate to reduce axial bias
    const mat2 rot = mat2(cos(0.5), sin(0.5), -sin(0.5), cos(0.50));

	for (int i = 0; i < n; ++i) {
		v += a * noise(x);
		x  = rot * x * scale + shift;
		a *= falloff;
	}
	return v;
}

////////////////////////////////////////////////////////////////////////
// Matrix Transformations

vec3 projectOrthographicMAD(in vec3 position, in mat4 projectionMatrix) {
    return vec3(projectionMatrix[0].x, projectionMatrix[1].y, projectionMatrix[2].z) * position + projectionMatrix[3].xyz;
}
vec2 projectOrthographicMAD(in vec2 position, in mat4x2 projectionMatrix) {
    return vec2(projectionMatrix[0].x, projectionMatrix[1].y) * position + projectionMatrix[3].xy;
}
vec3 projectPerspectiveMAD(in vec3 position, in mat4 projectionMatrix) {
    return projectOrthographicMAD(position, projectionMatrix) / -position.z;
}
vec2 projectPerspectiveMAD(in vec3 position, in mat4x2 projectionMatrix) {
    return projectOrthographicMAD(position.xy, projectionMatrix) / -position.z;
}
vec4 projectHomogeneousMAD(in vec3 position, in mat4 projectionMatrix) {
    return vec4(projectOrthographicMAD(position, projectionMatrix), -position.z);
}

vec3 unprojectOrthographicMAD(in vec2 position, in mat4 inverseProjectionMatrix) {
    return vec3(vec2(inverseProjectionMatrix[0].x, inverseProjectionMatrix[1].y) * position + inverseProjectionMatrix[3].xy, inverseProjectionMatrix[3].z);
}
vec3 unprojectPerspectiveMAD(in vec3 position, in mat4 inverseProjectionMatrix) {
    return unprojectOrthographicMAD(position.xy, inverseProjectionMatrix) / (inverseProjectionMatrix[2].w * position.z + inverseProjectionMatrix[3].w);
}
vec4 unprojectHomogeneousMAD(in vec3 position, in mat4 inverseProjectionMatrix) {
    return vec4(unprojectOrthographicMAD(position.xy, inverseProjectionMatrix), inverseProjectionMatrix[2].w * position.z + inverseProjectionMatrix[3].w);
}
vec3 transformMAD(in vec3 position, in mat4 transformationMatrix) {
    return mat3(transformationMatrix) * position + transformationMatrix[3].xyz;
}


////////////////////////////////////////////////////////////////////////
// Other Matrix Functions

mat2 rotationMatrix2(float angle) {
    float ca = cos(angle);
    float sa = sin(angle);
    return mat2(ca, sa, -sa, ca);
}

vec3 arbitraryTangent(vec3 normal) {
    // Equivalent to: normalize( cross(normal, vec3(0,0,1)) )
    return vec3(normal.y, -normal.x, 0) * (1 / sqrt( sqmag( normal.xy ) ));
}

mat3 arbitraryTBN(vec3 normal) {
    // Equivalent to: cross(normal, vec3(0,0,1))
    vec3 tangent  = vec3(normal.y, -normal.x, 0);
    // Equivalent to: cross(normal, tangent)
    vec3 binomial = vec3(-normal.x * normal.z, normal.x * normal.z, (normal.y * normal.y) + (normal.x * normal.x));
    return mat3(normalize(tangent), normalize(binomial), normal);
}


////////////////////////////////////////////////////////////////////////
// Color-Specific functions

vec3 saturation(vec3 col, float saturation) {
    float brightness = dot(col, vec3(0.299, 0.587, 0.112));
    return mix(vec3(brightness), col, saturation);
}

vec3 contrast(vec3 col, float contrast) {
    vec3 lower = (contrast * col) * (col * col);
    vec3 upper = 1 - contrast * sq(col - 1);
    return mix(lower, upper, col);
}

float luminance(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

vec3 rgb2hsv(vec3 c) {
    const vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}
vec3 hsv2rgb(vec3 c) {
    const vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 gamma(inout vec3 color) {
    color = pow(color, vec3(GAMMA));
    return color;
}
vec3 gamma_inv(vec3 color) {
    color = pow(color, vec3(1 / GAMMA));
    return color;
}

/////////////////////////////////////////////////////////////////////////////////
//                              OTHER FUNCTIONS

float map(float value, float min1, float max1, float min2, float max2) {
  return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}
float mapclamp(float value, float from_min, float from_max, float to_min, float to_max) {
    return clamp(map(from_min, from_max, to_min, to_max, value), to_min, to_max);
}

vec2 convertPolarCartesian(vec2 coord) {
    return vec2(coord.x * cos(coord.y), coord.x * sin(coord.y));
}

float linearizeDepth(float d,float nearPlane,float farPlane) {
    d = 2.0 * d - 1.0; // Convert to NDC (normalized device coordinates)
    return 2.0 * nearPlane * farPlane / (farPlane + nearPlane - d * (farPlane - nearPlane));
}
float linearizeDepthf(float d, float slope) { // For matching results, slope should be set to 1/nearPlane
    return 1 / ((-d * slope) + slope);
}
float linearizeDepthfDivisor(float d, float slope) { // Returns 1 / linearizeDepthf For matching results, slope should be set to 1/nearPlane
    return (-d * slope) + slope;
}
float linearizeDepthfInverse(float ld, float slope) { // For matching results, slope should be set to 1/nearPlane
    return -1 / (ld * slope) + 1;
}

float schlickFresnel(vec3 viewRay, vec3 normal, float refractiveIndex, float baseReflectiveness) {
    //Schlick-Approximation of Fresnel
    float R0 = (1 - refractiveIndex) / (1 + refractiveIndex);
    R0 *= R0;

    float cosAngle = dot(viewRay, normal);
    float reflectiveness = R0 + ( (1 - R0) * pow(1 - cosAngle, 5) );
    reflectiveness = clamp(1 - reflectiveness, 0, 1) + baseReflectiveness;
    return reflectiveness;
}
float schlickFresnel(vec3 viewDir, vec3 normal, float F0) {
    float NormalDotView = dot(-viewDir, normal);
    return F0 + (1.0 - F0) * pow(1.0 - NormalDotView, 5.0);
}
float customFresnel(vec3 viewRay, vec3 normal, float bias, float scale, float power) {
    float reflectiveness = clamp(bias + scale * pow(1.0 + dot(viewRay, normal), power), 0, 1); 
    return reflectiveness;
}

// Spins A point around the origin (negate for full coverage)
vec2 spiralOffset(float x, float expansion) {
    float n = fract(x * expansion) * PI;
    return vec2(cos(n), sin(n)) * x;
}
vec2 spiralOffset_full(float x, float expansion) {
    float n = fract(x * expansion) * TWO_PI;
    return vec2(cos(n), sin(n)) * x;
}


vec2 radClamp(vec2 coord) {
    // Center at 0,0
    coord = coord - 0.5;
    // Calculate oversize vector by subtracting 1 on each axis from the absulute
    // We just need the length so sing doesnt matter
    vec2 oversize = max(vec2(0), abs(coord) - 0.5);
    coord        /= (length(oversize) + 1);
    coord         = coord + 0.5;
    return coord;
}
vec3 radClamp(vec3 coord) {
    // Center at 0,0
    coord = coord - 0.5;
    // Calculate oversize vector by subtracting 1 on each axis from the absulute
    // We just need the length so sign doesnt matter
    vec3 oversize = max(vec3(0), abs(coord) - 0.5);
    coord /= (length(oversize) + 1);
    coord = coord + 0.5;
    return coord;
}
vec2 mirrorClamp(vec2 coord) { //Repeats coords while mirroring them (without branching)

    // Determines whether an axis has to be flipped or not
    vec2 reversal = mod(floor(coord), vec2(2));
    vec2 add      = reversal;
    vec2 mult     = reversal * -2 + 1;

    coord         = fract(coord);
    // Flips the axis
    // Flip:    1 - coord = -1 * coord + 1
    // No Flip:     coord =  1 * coord + 0
    // Using these expressions I can make the flipping branchless
    coord         = mult * coord + add;

    return coord;
}


float smoothCutoff(float x, float cutoff, float taper) {
    if (x > cutoff + taper) {return x;}
    float a   = cutoff / (taper*taper*taper);
    float tmp = (x - cutoff - taper);
    return clamp( (a * tmp) * (tmp * tmp) + x ,0,1);
}

float angle(vec2 v) {
    float ang = HALF_PI - atan(v.x / v.y);
    if(v.y < 0) {ang = ang + PI;}
    return ang;
}
