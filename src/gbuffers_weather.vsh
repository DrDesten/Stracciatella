#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/core/kernels.glsl"

#ifdef ANGLED_DOWNFALL

	#include "/lib/vertex_transform.glsl"
	
	#ifdef WORLD_TIME_ANIMATION

		uniform int worldTime;
	
		vec3 wavyRain(vec3 playerPos, float amount, float speed) {
			vec3 offset = vec3(sin((worldTime * (1./24.)) * speed), 0, cos((worldTime * (1./24.)) * speed));
			offset     *= playerPos.y * amount;
			return offset;
		}

	#else

		uniform float frameTimeCounter;

		vec3 wavyRain(vec3 playerPos, float amount, float speed) {
			vec3 offset = vec3(sin(frameTimeCounter * speed), 0, cos(frameTimeCounter * speed));
			offset     *= playerPos.y * amount;
			return offset;
		}

	#endif

#else
	#include "/lib/vertex_transform_simple.glsl"
#endif

flat out vec2 lmcoord;
out vec2 coord;
flat out vec4 glcolor;

void main() {
	#ifdef ANGLED_DOWNFALL

	vec3 playerPos = getPlayer();
	vec3 offset    = wavyRain(playerPos, ANGLED_DOWNFALL_AMOUNT, ANGLED_DOWNFALL_ROTATION_SPEED * 0.1);
	gl_Position    = playerToClip(playerPos + offset);

	#else

	gl_Position = getPosition();

	#endif

	coord   = getCoord();
	lmcoord = getLmCoord();
	glcolor = gl_Color;
}