#version 300 es
precision highp float;

#define FISH 0
#define TERRIAN 1

in vec4 fs_Pos;
in vec4 fs_Nor;
in vec4 fs_Col;
in vec2 fs_UV;
in vec4 fs_WorldNor;
in vec4 fs_PosWorld;

uniform float u_Time;
uniform vec3 u_Center;
uniform int u_Type;
out vec4 fragColor[4]; // The data in the ith index of this array of outputs
                       // is passed to the ith index of OpenGLRenderer's
                       // gbTargets array, which is an array of textures.
                       // This lets us output different types of data,
                       // such as albedo, normal, and position, as
                       // separate images from a single render pass.

uniform sampler2D tex_Color;
uniform sampler2D tex_Noise;

const float NEAR = 0.1;
const float FAR = 100.0;
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

// This one has non-ideal tiling properties that I'm still tuning
float noise(vec3 x) {
	const vec3 step = vec3(110, 241, 171);

	vec3 i = floor(x);
	vec3 f = fract(x);
 
	// For performance, compute the base input to a 1D hash from the integer part of the argument and the 
	// incremental change to the 1D based on the 3D -> 1D wrapping
    float n = dot(i, step);

	vec3 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix( hash(n + dot(step, vec3(0, 0, 0))), hash(n + dot(step, vec3(1, 0, 0))), u.x),
                   mix( hash(n + dot(step, vec3(0, 1, 0))), hash(n + dot(step, vec3(1, 1, 0))), u.x), u.y),
               mix(mix( hash(n + dot(step, vec3(0, 0, 1))), hash(n + dot(step, vec3(1, 0, 1))), u.x),
                   mix( hash(n + dot(step, vec3(0, 1, 1))), hash(n + dot(step, vec3(1, 1, 1))), u.x), u.y), u.z);
}


float LinearizeDepth(float d)
{
	float z = d * 2.0 - 1.0;
	return (2.0 * NEAR * FAR)/(FAR + NEAR - z * (FAR-NEAR));
}
void main() {
    // TODO: pass proper data into gbuffers
    // Presently, the provided shader passes "nothing" to the first
    // two gbuffers and basic color to the third.
	int inType = u_Type;
	vec3 col = vec3(0.0);	
	switch (inType)
	{
		case FISH:
		{
			col = texture(tex_Color, fs_UV).rgb;
		}break;
		case TERRIAN:
		{
			// float texTime1 = (sin(u_Time/50.0) + 1.0) / 4.0;
			// float texTime2 = (sin(u_Time / 25.0) + 1.0) / 4.0;
			// col = (texture(tex_Color, fs_UV/2.0 + vec2(texTime1) ).rgb + texture(tex_Noise, fs_UV/2.0 + vec2(texTime2) ).rgb) / 2.0;
			col = vec3(1.0);
			// col = texture(tex_Noise, fs_UV).xyz;
		}break;
		default:
		{

		}
		break;
	}
    

    // if using textures, inverse gamma correct
    col = pow(col, vec3(2.2));

	float z_buffer = LinearizeDepth(gl_FragCoord.z);
	float depth = abs(fs_Pos.z / (100.0 - 0.1));

	// 32 bit: normal and z_buffer
    fragColor[0] = vec4(normalize(fs_Nor).xyz, z_buffer);

	// 8 bit camera space positions

    // fragColor[1] = vec4(fs_Pos.xyz, z_cloudDepth);

    fragColor[1] = vec4(depth);


	// 8 bit: color 
    fragColor[2] = vec4(col, 1.0);

	fragColor[3] = vec4(fs_Pos.xyz, 1.0);

}
