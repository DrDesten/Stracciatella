const float sunLength = length(sunPosition);
uniform vec3 sunDir = sunPosition / sunLength;

const float moonLength = length(moonPosition);
uniform vec3 moonDir = moonPosition / moonLength;

const float upLength = length(mat3(gbufferModelView) * vec3(0, 1, 0));
uniform vec3 up = mat3(gbufferModelView) * vec3(0, 1, 0) / upLength;

const float dayLength = (12786.0 + 785.0) / 24000.0;
const float nightLength = 1. - dayLength;
const float normalizedTimeAligned = fract((float(worldTime) + 785.0) / 24000.0);

uniform vec2 screenSize        = vec2(viewWidth, viewHeight);
uniform vec2 screenSizeInverse = 1.0 / screenSize;

uniform vec2 lightPositionClip = (gbufferProjection * vec4(sunPosition, 1)).xy / -sunPosition.z;