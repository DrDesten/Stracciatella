#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/core/kernels.glsl"
#include "/lib/vertex_transform_simple.glsl"
#include "/lib/transform.glsl"

out vec2 lmcoord;
flat out vec4 glcolor;
out vec3 viewPos;
flat out int materialId;

float getBlockShade(vec3 playerNormal) {
    playerNormal /= maxc(abs(playerNormal));

    const float brightnessLevels[6] = float[](
        0.85, 0.85, // +x, -x (east, west)
        1, 0.5,     // +y, -y (up, down)
        0.75, 0.75  // +z, -z (south, north)
    );
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
    viewPos     = getView();
    materialId  = dhMaterialId;
    gl_Position = ftransform();

    vec3 viewNormal   = getNormal();
    vec3 playerPos    = toPlayer(viewPos);
    vec3 playerNormal = normalize(toPlayer(viewPos + viewNormal) - playerPos);

    float shade = getBlockShade(playerNormal);
    if (materialId == DH_BLOCK_LEAVES) {
        shade = (shade - 1) * 0.5 + 1;
    }

    glcolor.rgb *= shade;
}