#version 300 es
precision highp float;

#define EPS 0.0001
#define PI 3.1415962

in vec2 fs_UV;
out vec4 out_Col;

uniform sampler2D u_gb0;
uniform sampler2D u_gb1;
uniform sampler2D u_gb2;
uniform sampler2D u_SSAONoise;
uniform float u_Time;
uniform vec3 u_Samples[64];
uniform mat4 u_View;
uniform vec4 u_CamPos; 
uniform mat4 u_ViewInv; 
uniform vec2 u_Dimension;
uniform mat4 u_Proj; 

const vec4 lightPos = vec4(100, 100, 0, 1); 

float lerp(float a, float b, float f)
{
	return a + f * (b - a);
}
float hash(float n) { return fract(sin(n) * 1e4); }
float hash(vec2 p) { return fract(1e4 * sin(17.0 * p.x + p.y * 0.1) * (0.1 + abs(sin(p.y * 13.0 + p.x)))); }

float noise(float x) {
	float i = floor(x);
	float f = fract(x);
	float u = f * f * (3.0 - 2.0 * f);
	return mix(hash(i), hash(i + 1.0), u);
}

float noise(vec2 x) {
	vec2 i = floor(x);
	vec2 f = fract(x);

	// Four corners in 2D of a tile
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));

	// Simple 2D lerp using smoothstep envelope between the values.
	// return vec3(mix(mix(a, b, smoothstep(0.0, 1.0, f.x)),
	//			mix(c, d, smoothstep(0.0, 1.0, f.x)),
	//			smoothstep(0.0, 1.0, f.y)));

	// Same code, with the clamps in smoothstep and common subexpressions
	// optimized away.
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}


void main() { 
	// read from GBuffers
	vec2 noiseScale = vec2(u_Dimension.x / 4.0, u_Dimension.y / 4.0);
	vec4 gb2 = texture(u_gb2, fs_UV);

	vec3 col = gb2.xyz;

	
	//float back = texture(u_gb1, fs_UV).x;
	
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
	vec3 normal = texture(u_gb0, fs_UV).xyz;
	float diffuseTerm = dot(normalize(vec3(normal)), normalize(vec3(lightPos - pos_World)));
	float ambientTerm = 0.5;
	// if(texture(u_gb1, fs_UV).x > 0.5) ambientTerm = 0.3;
	float term = clamp(diffuseTerm, 0.0, 1.0) + ambientTerm;

	if(texture(u_gb1, fs_UV).x > 0.5) term = 1.0;
	col = col * term;

    // ==================== SSAO ======================//
	// std::uniform_real_distribution<GLfloat> randomFloats(0.0, 1.0); // 随机浮点数，范围0.0 - 1.0
	// std::default_random_engine generator;
	// std::vector<glm::vec3> ssaoKernel;
	// for (GLuint i = 0; i < 64; ++i)
	// {
    // 	glm::vec3 sample(
    //     randomFloats(generator) * 2.0 - 1.0, 
    //     randomFloats(generator) * 2.0 - 1.0, 
    //     randomFloats(generator)
    // );
    // sample = glm::normalize(sample);
    // sample *= randomFloats(generator);
    // GLfloat scale = GLfloat(i) / 64.0; 
	// scale = lerp(0.1f, 1.0f, scale * scale);
   	// sample *= scale;
    // ssaoKernel.push_back(sample);  
	// }


	

	

	vec3 fragPos = texture(u_gb1, fs_UV).xyz;
	vec3 ao_normal = texture(u_gb0, fs_UV).xyz;
	float z_buffer = texture(u_gb0, fs_UV).w / 100.0;
	vec3 randomVec = texture(u_SSAONoise, fs_UV * noiseScale).xyz;
	vec3 tangent = normalize(randomVec - ao_normal * dot(randomVec, ao_normal));
	vec3 bitangent = cross(ao_normal, tangent);
	mat3 TBN = mat3(tangent, bitangent, ao_normal);
	float occlusion = 0.0;
	float radius = 1.0;
	for(int i = 0; i < 64; ++i)
	{
		float a = noise(fs_UV) * 2.0 - 1.0;
		float b = noise(fs_UV * 10.0) * 2.0 - 1.0;
		float c = noise(fs_UV * 100.0);
		vec3 mySample = vec3(a,b,c);
		mySample = normalize(mySample);
		mySample = mySample * noise(mySample.x);
		float myScale = float(i) / 64.0;
		myScale = lerp(0.1, 1.0, myScale * myScale);
		vec3 ssaoKernel = mySample * myScale;


		vec3 ssaoSample = TBN * ssaoKernel;
		ssaoSample = fragPos + ssaoSample * radius;
		vec4 offset = vec4(ssaoSample, 1.0);
		offset = u_Proj * offset;
		offset.xyz /= offset.w;
		offset.xyz = offset.xyz * 0.5 + 0.5;
		occlusion += (z_buffer >= ssaoSample.z? 1.0 : 0.0);
	}

	out_Col = vec4(vec3(z_buffer), 1.0);
	//out_Col = vec4(u_Samples[0] * 100.0, 1.0);

	//out_Col = vec4(vec3(occlusion /100.0), 1.0);
	//out_Col = vec4(noise, 0.0, 0.0, 1.0);
	//out_Col = vec4( 0.0, 1.0, 0.0, 1.0);

}