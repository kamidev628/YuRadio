#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(binding = 1) uniform sampler2D source;

layout(std140, binding = 0) uniform buf {
  mat4 qt_Matrix;
  float qt_Opacity;
};


void main(void) {
  float dist = distance(qt_TexCoord0, vec2(0.5));
  float delta = fwidth(dist);

  vec4 tex = texture(source, qt_TexCoord0);

  float borderThickness = 0.02;
  float halfBorderThickness = borderThickness / 2;

  vec4 borderColor = vec4(0.67, 0.27, 0.94, 1);

  float radius = 0.5 - halfBorderThickness;

  float t1 = smoothstep(radius - delta - halfBorderThickness, radius - halfBorderThickness + delta, dist);
  float t2 = smoothstep(radius - delta + halfBorderThickness, radius + halfBorderThickness + delta, dist);

  vec4 roundImage = mix(tex, borderColor, t1);

  fragColor = mix(roundImage, vec4(0.0), t2) * qt_Opacity;
}
