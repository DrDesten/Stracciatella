if (sneaking > 1e-5) {
    const float scaleFactor = -pow(SNEAK_OUTLOOK_RADIUS + 1e-30, -4);
    vec3 player = toPlayer(toView(gl_Position.xyz / gl_Position.w));
    player.y   -= SNEAK_OUTLOOK_HEIGHT * (1 - exp(sq(sqmag(vec3(player.x, player.y - 1, player.z))) * scaleFactor)) * sneaking;
    gl_Position = playerToView4(player);
    //gl_Position.z *= -0.3 * sneaking + 1;
    gl_Position.xy *= 1 + (gl_Position.z * -0.005) * sneaking;
    gl_Position = viewToClip(gl_Position);
}