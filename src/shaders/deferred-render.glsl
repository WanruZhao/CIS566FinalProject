#version 300 es
precision highp float;

#define EPS 0.0001
#define PI 3.1415962

in vec2 fs_UV;
out vec4 out_Col;

uniform sampler2D u_gb0;
uniform sampler2D u_gb1;
uniform sampler2D u_gb2;

uniform float u_Time;

uniform mat4 u_View;
uniform vec4 u_CamPos; 
uniform mat4 u_ViewInv; 

const vec4 lightPos = vec4(100, 100, 0, 1); 


void main() { 
	// read from GBuffers

	vec4 gb2 = texture(u_gb2, fs_UV);

	vec3 col = gb2.xyz;

	
	float back = texture(u_gb1, fs_UV).x;
	
	// calculate camera space position
	vec2 uv_ndc = fs_UV * 2.0 - 1.0;
	vec4 gb0 = texture(u_gb0, fs_UV);
	float t = gb0.w;
	vec4 ref = t * vec4(0, 0, 1.0, 0);
	vec4 v = vec4(0, 1, 0, 0) * t * tan(45.0 * PI / 180.0 / 2.0);
	vec4 u = vec4(1, 0, 0, 0) * t * 1.0 * tan(45.0 * PI / 180.0 / 2.0);
	vec4 pos_Cam = ref + uv_ndc.x * u + uv_ndc.y * v;

	// calculate world space position
	vec4 pos_World = u_ViewInv * pos_Cam + u_CamPos;

	// lambertian model
	vec4 normal = texture(u_gb0, fs_UV);
	float diffuseTerm = dot(normalize(vec3(normal)), normalize(vec3(lightPos - pos_World)));
	float ambientTerm = 0.0;
	if(texture(u_gb1, fs_UV).x > 0.5) ambientTerm = 0.3;
	float term = clamp(diffuseTerm, 0.0, 1.0) + ambientTerm;

	if(texture(u_gb1, fs_UV).x > 0.5) term = 1.0;

	out_Col = vec4(col , 1.0);

}