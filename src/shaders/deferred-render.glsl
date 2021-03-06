#version 300 es
precision highp float;

#define EPS 0.0001
#define PI 3.1415962

in vec2 fs_UV;
out vec4 out_Col;

uniform sampler2D u_gb0;
uniform sampler2D u_gb1;
uniform sampler2D u_gb2;
uniform sampler2D u_gb3;
uniform sampler2D u_SSAONoise;
uniform sampler2D u_Water1;
uniform sampler2D u_Water2;
uniform vec3 u_Samples[64];
uniform mat4 u_View;
uniform mat4 u_Model;
uniform vec4 u_CamPos; 
uniform mat4 u_ViewInv; 
uniform vec2 u_Dimension;
uniform mat4 u_Proj; 
uniform float u_Time;


const vec4 lightPos = vec4(-5,-5, -10, 1); 

vec3 depthFog(vec3 col, float t) {
	return mix(col, vec3(0.8, 0.6, 0.2), t);
}

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
	float ambientTerm = 0.2;
	// if(texture(u_gb1, fs_UV).x > 0.5) ambientTerm = 0.3;
	float term = clamp(diffuseTerm, 0.0, 1.0) + ambientTerm;

	// if(texture(u_gb1, fs_UV).x > 0.5) term = 1.0;
	term = clamp(term, 0.0, 1.0);

	if(fs_UV.x < 0.5) {
		col += vec3(0.8, 0.6, 0.2) * 0.5;
	} else {
		col += vec3(0.0, 0.2, 0.2) * 0.5;
	}

	col = clamp(col, vec3(0.0), vec3(1.0));
	

    // ==================== SSAO ======================//
	vec3 fragPos = texture(u_gb3, fs_UV).xyz;
	vec3 ao_normal = texture(u_gb0, fs_UV).xyz;
	float z_buffer = texture(u_gb0, fs_UV).w / (100.0 - 0.1);
	vec3 randomVec = normalize(texture(u_SSAONoise, fs_UV * noiseScale).xyz);
	vec3 tangent = normalize(randomVec - ao_normal * dot(randomVec, ao_normal));
	vec3 bitangent = cross(ao_normal, tangent);
	mat3 TBN = mat3(tangent, bitangent, ao_normal);
	float occlusion = 0.0;
	float radius = 1.0;

	for(int i = 0; i < 64; ++i)
	{
		vec3 mySample = TBN * u_Samples[i];
		mySample = fragPos + u_Samples[i] * radius;
		vec4 offset = vec4(mySample, 1.0);
		offset = u_Proj * offset;
		offset.xyz /= offset.w;
		offset.xyz = offset.xyz * 0.5 + 0.5;
		float sampleDepth = texture(u_gb3, offset.xy).z;


		// convert cam depth to world depth
		// vec3 samplePos = texture(u_gb3, offset.xy).xyz;
		// vec3 sampleWorldPos = (u_ViewInv * vec4(samplePos, 1.0)).xyz + u_CamPos.xyz;
		// float sampleDepth = sampleWorldPos.z;

		float rangeCheck = smoothstep(0.0, 1.0, radius / abs(fragPos.z - sampleDepth));
		occlusion += (sampleDepth >= mySample.z + 0.025? 1.0 : 0.0 ) * rangeCheck;
	}
	
	occlusion = 1.0 - (occlusion / 64.0);


	float texTime1 = (sin(u_Time/80.0) + 1.0) / 4.0;
	float texTime2 = (sin(u_Time/40.0) + 1.0) / 4.0;
	float texTime3 = (cos(u_Time/ 50.0) + 1.0) / 4.0;
	float texTime4 = (cos(u_Time/ 40.0) + 1.0) / 4.0;
	// col = (texture(tex_Color, fs_UV/2.0 + vec2(texTime1) ).rgb + texture(tex_Noise, fs_UV/2.0 + vec2(texTime2) ).rgb) / 2.0;
	// col = vec3(1.0);
	vec3 waterCol = (texture(u_Water1, fs_UV/2.0 + vec2(texTime1, texTime3) ).rgb + texture(u_Water2, fs_UV/2.0 + vec2(texTime2, texTime4) ).rgb) / 2.0;
	if(fs_UV.x > 0.5) {
		
		col *= term * occlusion;
		col = mix(col, vec3(0.0, 0.6, 0.8), 0.1);
		col += waterCol * 0.2;
	} else {
		col = depthFog(col * term * occlusion, z_buffer);
	}
	// vec3 waterCol = texture(u_Water2, fs_UV/2.0 + vec2(texTime2) ).rgb;
	
	// out_Col = vec4(vec3(z_buffer), 1.0);
	// out_Col = vec4(u_Samples[50], 1.0);
		// out_Col = vec4(randomVec, 1.0);
	// out_Col = vec4(vec3(occlusion), 1.0);
	// out_Col = vec4(gl_FragCoord.xy / u_Dimension, 0.0, 1.0);
	out_Col = vec4(col, 1.0);


	// out_Col = vec4(, 0.0, 1.0);
	//out_Col = vec4(noise, 0.0, 0.0, 1.0);
	//out_Col = vec4( 0.0, 1.0, 0.0, 1.0);

}