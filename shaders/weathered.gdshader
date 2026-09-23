shader_type spatial;
render_mode diffuse_burley;
uniform vec4 base_color : source_color = vec4(0.25, 0.16, 0.08, 1.0);
uniform bool timber = false;
uniform bool floor_surface = false;
uniform float wear : hint_range(0.0,1.0) = 0.9;
varying vec3 world_pos;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f*f*(3.0-2.0*f);
    return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void vertex() { world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
    vec2 p = world_pos.xz + world_pos.y * vec2(0.37,0.59);
    float stains = noise(p*0.65)*0.65 + noise(p*2.8)*0.35;
    float grit = noise(p*95.0);
    float damp = smoothstep(0.40,0.74,stains);
    vec3 color = base_color.rgb * mix(0.48,1.0,stains);
    color = mix(color, color*vec3(0.40,0.48,0.34), damp*0.6);
    if(timber) {
        float grain = noise(vec2(p.x*18.0 + noise(p*1.8)*2.0, p.y*1.4));
        color *= mix(0.76,1.10,grain);
        float scratches = smoothstep(0.77,0.87,noise(vec2(p.x*55.0,p.y*3.0)));
        color = mix(color,base_color.rgb*1.12,scratches*0.24);
    }
    float edge_dust = floor_surface ? smoothstep(7.3,11.4,abs(p.x))+smoothstep(5.7,8.3,abs(p.y)) : 0.15;
    color = mix(color, vec3(0.24,0.21,0.16), clamp(edge_dust*0.43+smoothstep(0.76,0.92,grit)*0.20,0.0,0.68));
    ALBEDO = mix(base_color.rgb,color,wear);
    ROUGHNESS = 0.94;
    SPECULAR = 0.13;
}
