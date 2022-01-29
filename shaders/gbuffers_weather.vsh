

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"

#ifdef ANGLED_RAIN

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

varying vec2 lmcoord;
varying vec2 coord;
varying vec4 glcolor;

void main() {
	#ifdef ANGLED_RAIN

	vec3 playerPos = getPlayer();
	vec3 offset    = wavyRain(playerPos, ANGLED_RAIN_AMOUNT, ANGLED_RAIN_ROTATION_SPEED * 0.1);
	gl_Position    = playerToClip(playerPos + offset);

	#else

	gl_Position = ftransform();

	#endif

	coord   = getCoord();
	lmcoord = getLmCoord();
	glcolor = gl_Color;
}