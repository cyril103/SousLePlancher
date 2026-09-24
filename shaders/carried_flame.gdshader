shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform float clock = 0.0;
uniform float seed = 0.0;
void vertex() {
    float tip = max(VERTEX.y,0.0);
    VERTEX.xz *= 1.0 - tip * 3.0;
    VERTEX.x += (sin(clock*7.0+seed)+0.4*sin(clock*17.0))*tip*0.28;
    VERTEX.z += cos(clock*9.0+seed)*tip*0.18;
    VERTEX.y *= 1.0+sin(clock*11.0+seed)*0.12;
}
void fragment() {
    float core = pow(max(0.0,sin(UV.y*3.14159)),0.7);
    ALBEDO = mix(vec3(1.0,0.20,0.015),vec3(1.0,0.85,0.30),core);
    ALPHA = mix(0.36,0.72,core);
}
