varying mediump vec2 textureCoordinate;
precision mediump float;

uniform sampler2D videoFrame;
uniform float red;
uniform float green;
uniform float blue;
uniform float contrast;

void main() {
    vec4 pixelColor;
    
	pixelColor = texture2D(videoFrame, textureCoordinate.st);
    pixelColor = contrast * pixelColor + (1.0 - contrast) * vec4(0.5);
	gl_FragColor = vec4(red * pixelColor.r, green * pixelColor.g, blue * pixelColor.b, pixelColor.a);
}

// ved contrast = 0 skal f(x) = 0.5
// ved kontrast = 1 skal f(x) = x
// ved kontrast = 0.5 skal f(0) = 0.25
//   så f(x) = c * x + (1.0 - c) * 0.5