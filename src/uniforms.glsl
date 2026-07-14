// Normalized Positions
const float sunLength  = length(sunPosition);
uniform vec3 sunDir    = sunPosition / sunLength;

const float moonLength = length(moonPosition);
uniform vec3 moonDir   = moonPosition / moonLength;

const float upLength   = length(mat3(gbufferModelView) * vec3(0, 1, 0));
uniform vec3 up        = mat3(gbufferModelView) * vec3(0, 1, 0) / upLength;

/*
shadowLightPosition switches from the sun to the moon at 12786 ticks and back to the sun at 23215 ticks
normalizedTime goes from 0 at sunrise to 0.5 at sunset to 1 at the next sunrise
*/

// length of the day in normalizedTimeAligned
const float dayLength             = (12786.0 + 785.0) / 24000.0;
// length of the night in normalizedTimeAligned
const float nightLength           = 1. - dayLength;
// normalizedTimeAligned starts and ends at sunrise
const float normalizedTimeAligned = fract((worldTime + 785.0) / 24000.0);
// Modifying normalizedTimeAligned to be 0.5 at sunset, thus satifying the conditions
// Step 1: Selecting if its day or night
// Step 2: Normalizing for the day and bringing it to [0.0;0.5] to align sunset
// Step 3: Normalizing for the night and bringing it to [0.5;1.0] to align sunset for this part as well
uniform float normalizedTime = normalizedTimeAligned < dayLength
    ? (normalizedTimeAligned / dayLength) * 0.5
    : ((normalizedTimeAligned - dayLength) / nightLength) * 0.5 + 0.5;

// Texture Sizes
uniform vec2 screenSize        = vec2(viewWidth, viewHeight);
uniform vec2 screenSizeInverse = 1.0 / screenSize;

// Calling it lightPosition because moon and sun have the same screen space coordinates
uniform vec2 lightPositionClip = (gbufferProjection * vec4(sunPosition, 1)).xy / -sunPosition.z;

// Weather
uniform int   precipitation     = biome_precipitation
uniform float playerTemperature = temperature
uniform float rainPuddle        = smooth(float(biome_precipitation == 1 && temperature >= 0.15), 1.5) * wetness

// Sunset Curve
uniform float sunset              = pow(cos(normalizedTime * pi * 4) * 0.5 + 0.5, 25)
// Brightness Curve
uniform float daynight            = clamp(sin(normalizedTime * pi * 2) + 0.6, 0, 1)
uniform float customLightmapBlend = clamp(sin(normalizedTime * pi * 2) + 0.6, 0, 1) * (rainStrength * -0.5 + 1)
uniform float customStarBlend     = clamp(sin(normalizedTime * pi * 2) * -4.25, 0, 1) * (1 - rainStrength)

uniform float farInverse          = 1.0 / far
uniform float nearInverse         = 1.0 / near