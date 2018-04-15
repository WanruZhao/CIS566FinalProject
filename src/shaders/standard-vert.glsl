#version 300 es
precision highp float;

uniform mat4 u_Model;
uniform mat4 u_ModelInvTr;  

uniform mat4 u_View;   
uniform mat4 u_Proj; 

uniform float u_Time;

in vec4 vs_Pos;
in vec4 vs_Nor;
in vec4 vs_Col;
in vec2 vs_UV;

out vec4 fs_Pos;
out vec4 fs_Nor;            
out vec4 fs_Col;           
out vec2 fs_UV;

void main()
{
    fs_Col = vs_Col;
    fs_UV = vs_UV;
    fs_UV.y = 1.0 - fs_UV.y;

    // fragment info is in view space
    mat3 invTranspose = mat3(u_ModelInvTr);
    mat3 view = mat3(u_View);
    fs_Nor = vec4(view * invTranspose * vec3(vs_Nor), 0);
    vec4 worldPos = vs_Pos;
    // worldPos.x += 5.0 * sin(u_Time / 2.0);


    float x_time = ((worldPos.z - 8.0) + 3.0) / 40.0 * sin(worldPos.z/ 20.0 + 5.0 * u_Time / 2.0) / 2.0;
    mat4 rotX = mat4(0.0);
    rotX[1][1] = cos(x_time);
    rotX[1][2] = -sin(x_time);
    rotX[2][1] = sin(x_time);
    rotX[2][2] = cos(x_time);
    rotX[0][0] = 1.0;
    rotX[3][3] = 1.0;
    rotX = transpose(rotX);

    // rotY along y axis
    mat4 rotY = mat4(0.0);
    rotY[0][0] = cos(1.0 * sin(u_Time / 5.0));
    rotY[0][2] = sin(1.0 * sin(u_Time / 5.0));
    rotY[2][0] = -sin(1.0 * sin(u_Time / 5.0));
    rotY[2][2] = cos(1.0 * sin(u_Time / 5.0));
    rotY[1][1] = 1.0;
    rotY[3][3] = 1.0;
    rotY = transpose(rotY);
    
    // rotZ along z axis
    mat4 rotZ = mat4(0.0);
    rotZ[0][0] = cos(sin(u_Time / 5.0));
    rotZ[0][1] = -sin(sin(u_Time / 5.0));
    rotZ[1][0] = sin(sin(u_Time / 5.0));
    rotZ[1][1] = cos(sin(u_Time / 5.0));
    rotZ[2][2] = 1.0;
    rotZ[3][3] = 1.0;
    rotZ = transpose(rotZ);


    mat4 tra = mat4(0.0);
    tra[0][0] = 1.0;
    tra[1][1] = 1.0;
    tra[2][2] = 1.0;
    tra[3][3] = 1.0;
    tra[0][3] = 5.0;
    tra[1][3] = 10.0;
    tra[2][3] = 5.0;
    tra = transpose(tra);
    
    

    worldPos =     rotX * worldPos; 

    fs_Pos = u_View * u_Model * worldPos;
    
    gl_Position = u_Proj * u_View * u_Model * worldPos;
}
