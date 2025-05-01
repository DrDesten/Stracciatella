#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/core/kernels.glsl"
#include "/lib/vertex_transform.glsl"

#define AMBIENT_ONLY
#include "/lib/sky.glsl"

out vec2 lmcoord;
out vec4 glcolor;
out vec3 worldPos;
flat out int materialId;

float getBlockShade(vec3 playerNormal) {
    playerNormal /= maxc(abs(playerNormal));

#if defined OVERWORLD
    const float brightnessLevels[6] = float[](
        0.8,  0.8, // +x, -x (east, west)
        1,    0.4, // +y, -y (up, down)
        0.65, 0.65 // +z, -z (south, north)
    );
#else 
    const float brightnessLevels[6] = float[](
        0.85, 0.85, // +x, -x (east, west)
        1,    1,    // +y, -y (up, down)
        0.7,  0.75  // +z, -z (south, north)
    );
#endif

    float components[6] = float[](
        saturate(playerNormal.x),
        saturate(-playerNormal.x),
        saturate(playerNormal.y),
        saturate(-playerNormal.y),
        saturate(playerNormal.z),
        saturate(-playerNormal.z)
    );

    float shade = 0;
    for (int i = 0; i < 6; i++) {
        shade += components[i] * brightnessLevels[i];
    }

    return shade;
}

void main() {
    glcolor     = gl_Color;
    lmcoord     = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    materialId  = dhMaterialId;
    gl_Position = getPosition();

    vec3 viewPos      = getView();
    vec3 viewNormal   = getNormal();
    vec3 playerPos    = toPlayer(viewPos);
    vec3 playerNormal = normalize(toPlayer(viewPos + viewNormal) - playerPos);
    worldPos          = toWorld(playerPos);

    float shade = getBlockShade(playerNormal);
    if (materialId == DH_BLOCK_LEAVES) {
        shade = (shade - 1) * 0.5 + 1;
    }

    if (worldPos.y > 400) {
        
        lmcoord.xy   = vec2(0,1);

        vec3 ambient = sqrtf01(getSkyAmbient() * 0.9 + 0.1);
        vec3 scatter = mix(ambient, vec3(avg(ambient)), 0.33);
        glcolor.rgb  = scatter;

    }

    glcolor.a = shade;
}