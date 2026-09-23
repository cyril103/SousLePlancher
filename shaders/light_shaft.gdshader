shader_type spatial;
render_mode unshaded, blend_add, cull_front, depth_draw_never, depth_test_disabled, shadows_disabled, fog_disabled;
// Integrate density inside a local volume; stop at opaque scene geometry.
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;
uniform vec3 beam_start;
uniform vec3 beam_end;
uniform vec3 bounds_min;
uniform vec3 bounds_max;
uniform vec3 tint : source_color = vec3(0.68,0.73,0.70);
uniform float width = 0.8;
uniform float seed = 0.0;
uniform float strength = 0.12;
uniform float daylight = 1.0;
uniform float flatten = 0.6;
float hash(vec3 p) { p=fract(p*.1031); p+=dot(p,p.yzx+33.33); return fract((p.x+p.y)*p.z); }
float noise(vec3 p) {
    vec3 i=floor(p),f=fract(p); f=f*f*(3.0-2.0*f);
    return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),
               mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);
}
float density(vec3 p) {
    vec3 axis=beam_end-beam_start;
    float t=dot(p-beam_start,axis)/dot(axis,axis);
    vec3 direction=normalize(axis);
    vec3 right=normalize(cross(direction,vec3(0,1,0)));
    vec3 up=cross(right,direction);
    vec3 rel=p-(beam_start+axis*t);
    float radius=width*(0.18+max(t,0.0)*0.94);
    vec2 q=vec2(dot(rel,right),dot(rel,up)/flatten)/max(radius,0.02);
    float cloud=noise(p*1.12+vec3(seed,TIME*.028,0));
    float fine=noise(p*3.2+vec3(0,seed,TIME*-.018));
    float profile=exp(-dot(q,q)*1.8);
    float ends=smoothstep(-.02,.09,t)*(1.0-smoothstep(.70,1.14,t));
    return profile*ends*(0.24+0.76*cloud)*(0.70+0.30*fine);
}
void fragment() {
    vec3 direction=normalize((INV_VIEW_MATRIX*vec4(0,0,-1,0)).xyz);
    vec3 origin=(INV_VIEW_MATRIX*vec4(VERTEX.xy,0,1)).xyz;
    if(PROJECTION_MATRIX[3][3] < 0.5) {
        origin=CAMERA_POSITION_WORLD;
        direction=normalize((INV_VIEW_MATRIX*vec4(VERTEX,1)).xyz-origin);
    }
    vec3 safe_dir=mix(vec3(-1.0),vec3(1.0),step(vec3(0.0),direction))*max(abs(direction),vec3(0.00001));
    vec3 t0=(bounds_min-origin)/safe_dir;
    vec3 t1=(bounds_max-origin)/safe_dir;
    vec3 lo=min(t0,t1),hi=max(t0,t1);
    float near_t=max(max(lo.x,lo.y),max(lo.z,0.0));
    float far_t=min(min(hi.x,hi.y),hi.z);
    float depth=texture(depth_texture,SCREEN_UV).r;
    #if CURRENT_RENDERER == RENDERER_COMPATIBILITY
    vec3 ndc=vec3(SCREEN_UV,depth)*2.0-1.0;
    #else
    vec3 ndc=vec3(SCREEN_UV*2.0-1.0,depth);
    #endif
    vec4 scene=INV_VIEW_MATRIX*INV_PROJECTION_MATRIX*vec4(ndc,1);
    scene.xyz/=scene.w;
    far_t=min(far_t,dot(scene.xyz-origin,direction));
    float step_size=max(0.0,far_t-near_t)/24.0;
    float integrated=0.0;
    float jitter=hash(vec3(FRAGCOORD.xy,seed));
    for(int i=0;i<24;i++) {
        vec3 p=origin+direction*(near_t+(float(i)+jitter)*step_size);
        integrated+=density(p)*step_size;
    }
    ALBEDO=tint;
    ALPHA=(1.0-exp(-integrated*strength))*daylight;
}
