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
    worldPos.x += 5.0 * sin(u_Time / 2.0);
    mat4 rot = mat4(0.0);
    rot[0][0] = cos(1.0 * sin(u_Time / 5.0));
    rot[0][2] = sin(1.0 * sin(u_Time / 5.0));
    rot[2][0] = -sin(1.0 * sin(u_Time / 5.0));
    rot[2][2] = cos(1.0 * sin(u_Time / 5.0));
    rot[1][1] = 1.0;
    rot[3][3] = 1.0;

    mat4 tra = mat4(0.0);
    tra[0][0] = 1.0;
    tra[1][1] = 1.0;
    tra[2][2] = 1.0;
    tra[3][3] = 1.0;
    tra[0][3] = 5.0;
    tra[1][3] = 10.0;
    tra[2][3] = 5.0;

    tra = transpose(tra);
    rot = transpose(rot);
    

    // worldPos =   tra * rot * worldPos; 

    fs_Pos = u_View * u_Model * worldPos;
    
    gl_Position = u_Proj * u_View * u_Model * worldPos;
}
