if (sneaking > 1e-6) {
    const float scaleFactor = -pow(SNEAK_OUTLOOK_RADIUS + 1e-30, -4);
    vec3 player = toPlayer(toView(gl_Position.xyz / gl_Position.w));
    player.y   -= SNEAK_OUTLOOK_HEIGHT * (1 - exp(sq(sqmag(vec3(player.x, player.y - 1, player.z))) * scaleFactor)) * sneaking;
    gl_Position = playerToClip(player);
}