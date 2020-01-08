#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

uniform sampler2D texture;
uniform float my_opacity;

varying vec4 vertColor;
varying vec4 vertTexCoord;

void main() {
  vec4 c = texture2D(texture, vertTexCoord.st) * vertColor;
  c.a *= my_opacity;
  gl_FragColor = c;
}