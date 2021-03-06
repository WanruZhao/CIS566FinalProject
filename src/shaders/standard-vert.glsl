#version 300 es
precision highp float;


#define FISH 0
#define TERRIAN 1

uniform mat4 u_Model;
uniform mat4 u_ModelInvTr;  

uniform mat4 u_View;   
uniform mat4 u_Proj; 
uniform float u_Time;
uniform vec3 u_Center;
in vec4 vs_Pos;
in vec4 vs_Nor;
in vec4 vs_Col;
in vec2 vs_UV;

out vec4 fs_Pos;
out vec4 fs_Nor;            
out vec4 fs_Col;           
out vec2 fs_UV;
out vec4 fs_WorldNor;
out vec4 fs_PosWorld;

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

void main()
{
    fs_Col = vs_Col;
    fs_UV = vs_UV;
    fs_UV.y = 1.0 - fs_UV.y;

    
    float m_Noise = noise(u_Center);
    // fragment info is in view space
    mat3 invTranspose = mat3(u_ModelInvTr);
    mat3 view = mat3(u_View);
    fs_Nor = vec4(view * invTranspose * vec3(vs_Nor), 0);
    vec4 worldPos = vs_Pos;
    worldPos.x += 3.0 * sin(u_Time / 2.0) + m_Noise;



    // float x_time = 3.0 * ((worldPos.z - 8.0) + 3.0) / 40.0 * sin(worldPos.z/ 20.0 + 5.0 * u_Time / 5.0) / 2.0 + 1.0 + 2.0 * m_Noise - 1.0; 
    float x_time = 3.0 * ((worldPos.z - 8.0) + 3.0) / 40.0 * sin((worldPos.z)/ 20.0 + 5.0 * (u_Time + (2.0 * m_Noise -1.0) * 10.0) / 5.0) / 2.0 + 1.0; 
    
    mat4 rotX = mat4(0.0);
    rotX[1][1] = cos(x_time);
    rotX[1][2] = -sin(x_time);
    rotX[2][1] = sin(x_time);
    rotX[2][2] = cos(x_time);
    rotX[0][0] = 1.0;
    rotX[3][3] = 1.0;
    rotX = transpose(rotX);

    // rotY along y axis
    float y_time = 0.5 * sin(u_Time / 5.0);
    mat4 rotY = mat4(0.0);
    rotY[0][0] = cos(y_time);
    rotY[0][2] = sin(y_time);
    rotY[2][0] = -sin(y_time);
    rotY[2][2] = cos(y_time);
    rotY[1][1] = 1.0;
    rotY[3][3] = 1.0;
    rotY = transpose(rotY);
    
    // rotZ along z axis
    float z_time = sin(u_Time * 2.5) / 15.0;
    mat4 rotZ = mat4(0.0);
    rotZ[0][0] = cos(z_time);
    rotZ[0][1] = -sin(z_time);
    rotZ[1][0] = sin(z_time);
    rotZ[1][1] = cos(z_time);
    rotZ[2][2] = 1.0;
    rotZ[3][3] = 1.0;
    rotZ = transpose(rotZ);

    mat4 tra = mat4(0.0);
    tra[0][0] = 1.0;
    tra[1][1] = 1.0;
    tra[2][2] = 1.0;
    tra[3][3] = 1.0;
    tra[0][3] = 5.0;
    tra[1][3] = 7.0;
    tra[2][3] = 2.0;
    tra = transpose(tra);
    
    float moveToSide = 40.0;
    mat4 CenterTra = mat4(0.0);
    CenterTra[0][0] = 1.0;
    CenterTra[1][1] = 1.0;
    CenterTra[2][2] = 1.0;
    CenterTra[3][3] = 1.0;
    CenterTra[0][3] = moveToSide - 80.0 * fract((u_Time + u_Center[0]*10.0) / 40.0);
    // CenterTra[0][3] = u_Center[0] + 25.0;
    CenterTra[1][3] = u_Center[1];
    CenterTra[2][3] = u_Center[2];
    CenterTra = transpose(CenterTra);

    float cameraRotXRad = -60.0 / 180.0 * 3.14159;
    mat4 cameraRotX = mat4(0.0);
    cameraRotX[1][1] = cos(cameraRotXRad);
    cameraRotX[1][2] = -sin(cameraRotXRad);
    cameraRotX[2][1] = sin(cameraRotXRad);
    cameraRotX[2][2] = cos(cameraRotXRad);
    cameraRotX[0][0] = 1.0;
    cameraRotX[3][3] = 1.0;
    cameraRotX = transpose(cameraRotX);

    float cameraRotYRad = -90.0 / 180.0 * 3.14159;
    mat4 cameraRotY = mat4(0.0);
    cameraRotY[0][0] = cos(cameraRotYRad);
    cameraRotY[0][2] = sin(cameraRotYRad);
    cameraRotY[2][0] = -sin(cameraRotYRad);
    cameraRotY[2][2] = cos(cameraRotYRad);
    cameraRotY[1][1] = 1.0;
    cameraRotY[3][3] = 1.0;
    cameraRotY = transpose(cameraRotY);

    float cameraRotZRad = 0.0 / 180.0 * 3.14159;
    mat4 cameraRotZ = mat4(0.0);
    cameraRotZ[0][0] = cos(cameraRotZRad);
    cameraRotZ[0][1] = -sin(cameraRotZRad);
    cameraRotZ[1][0] = sin(cameraRotZRad);
    cameraRotZ[1][1] = cos(cameraRotZRad);
    cameraRotZ[2][2] = 1.0;
    cameraRotZ[3][3] = 1.0;
    cameraRotZ = transpose(cameraRotZ);

    float scaleFactor = 0.3 + 0.1 * (2.0 * m_Noise - 1.0);
    mat4 scaleMatrix = mat4(0.0);
    scaleMatrix[0][0] = scaleFactor;
    scaleMatrix[1][1] = scaleFactor;
    scaleMatrix[2][2] = scaleFactor;
    scaleMatrix[3][3] = 1.0;


    // int inType = u_Type;
    // switch(inType)
    // {
    //     case FISH:
    //     {
            worldPos =  CenterTra * cameraRotY * cameraRotX * rotX *  scaleMatrix * worldPos; 

            fs_PosWorld = worldPos;
            fs_Pos = u_View * u_Model * worldPos;
            gl_Position = u_Proj * u_View * u_Model * worldPos;
    //     } break;
    //     case TERRIAN:
    //     {
    //         fs_PosWorld = vs_Pos;
    //         fs_Pos = u_View * u_Model * vs_Pos;
    //         gl_Position = u_Proj * u_View * u_Model * vs_Pos;
    //     } break;
    //     default:
    //     {

    //     }break;
    // }
    // worldPos = CenterTra * cameraRotY * cameraRotX * rotX * worldPos; 

// ========================== bird movements ===========================================//

//     vec4 birdPos = vec4(0.0);
//     float x_time = u_Time;
//     mat4 rotX = mat4(0.0);
//     rotX[1][1] = cos(x_time);
//     rotX[1][2] = -sin(x_time);
//     rotX[2][1] = sin(x_time);
//     rotX[2][2] = cos(x_time);
//     rotX[0][0] = 1.0;
//     rotX[3][3] = 1.0;
//    rotX = transpose(rotX);

    // mat4 rotX2 = mat4(0.0);
    // rotX2[1][1] = cos(-x_time);
    // rotX2[1][2] = -sin(-x_time);
    // rotX2[2][1] = sin(-x_time);
    // rotX2[2][2] = cos(-x_time);
    // rotX2[0][0] = 1.0;
    // rotX2[3][3] = 1.0;
    
   // rotX2 = transpose(rotX2);
    //birdPos *= rotX;

    // if(vs_Pos.z > 0.000005)
    // {
    //     birdPos = rotX * vs_Pos;
    // }
    // else 
    // {
    //     birdPos = vs_Pos;
    // }
    // if(birdPos.x < 0.)
    // {
    //     birdPos *= rotX;
    // }
    // else
    // {
    // //     birdPos *= rotX2;
    // }
    // if(birdPos.z <= 0.0)
    // {
    //     birdPos *= rotX;
    // }
    

    
    // fs_Pos = u_View * u_Model * birdPos;
    // gl_Position = u_Proj * u_View * u_Model * birdPos;
}
