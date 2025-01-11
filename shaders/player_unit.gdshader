shader_type canvas_item;

const float twoPI = 2.0*PI;

uniform float outline_width = 0.02;
uniform float max_width = 0.1;
uniform vec4 outline_color: source_color = vec4(1,0,0,1);
uniform bool selected = false;
uniform float angle_step = 0.5;


float rand(vec2 co){
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

mat2 rot(float theta){
	float s = sin(theta);
	float c = cos(theta);
	return mat2(vec2(c, -s), vec2(s,c));
}

vec2 texOff(float theta){
	return rot(theta) * vec2(outline_width, 0.0);
}

float outline_mask(sampler2D tex, vec2 uv){
	float a = 0.0;
	float angle_off = rand(uv) * twoPI;
	for(float r = 0.0; r < twoPI; r += angle_step){
		a += texture(tex, uv+texOff(r+angle_off)).a;
	}
	return min(a, 1.0);
}

void fragment() {
	vec4 col = texture(TEXTURE, UV) * COLOR;
	if(selected){
		float a = 1.0;
		if(outline_width < max_width){
			a = outline_mask(TEXTURE, UV);
		}
		vec4 outline = mix(vec4(0),outline_color,a);
		col = mix(outline, col, col.a);
	}

	COLOR = col;
}