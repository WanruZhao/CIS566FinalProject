#version 300 es
precision highp float;

uniform vec2 u_Dimension;
uniform sampler2D u_frame;

out vec4 out_Col;

in vec2 fs_UV;

void main() {

    vec2 uv = gl_FragCoord.xy / u_Dimension;
    vec3 col = texture(u_frame, fs_UV).xyz;
    if(uv.x > 0.3 && uv.x < 0.7) {
        
        // float vig = abs(uv.x - 0.5) * 5.0;
        float vig = pow(abs(uv.x - 0.5) * 16.0, 0.3);
        vig = clamp(vig, 0.3, 1.0);
        col = col * vig;
        out_Col = vec4(col, 1.0);
    }

    else out_Col = vec4(col, 1.0);

}