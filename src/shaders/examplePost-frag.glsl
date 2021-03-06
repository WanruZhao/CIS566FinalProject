#version 300 es
precision highp float;

in vec2 fs_UV;
out vec4 out_Col;

uniform sampler2D u_frame;
uniform float u_Time;

// Interpolation between color and greyscale over time on left half of screen
void main() {

	out_Col = texture(u_frame, fs_UV);

}
