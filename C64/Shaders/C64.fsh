varying mediump vec2 textureCoordinate;
precision mediump float;

uniform sampler2D videoFrame;
uniform sampler2D ditherMap;
uniform sampler2D paletteMap;
uniform float scale;

void main() {
    vec4 pixelColor;
    vec3 YCrCb;
    ivec2 ditherSize;
    float blue, x, y;
    vec2 pos;
    
	pixelColor = texture2D(videoFrame, textureCoordinate.st);
    pixelColor = pixelColor + 0.15 * (texture2D(ditherMap, textureCoordinate.st * scale) - 0.5);
    
    blue = floor(pixelColor.b * 15.0);
    x = 16.0 * mod(blue, 4.0) + floor(pixelColor.r * 15.0);
    y = 16.0 * floor(blue / 4.0) + floor(pixelColor.g * 15.0);
    pos = vec2(x, y) / 64.0;
    pixelColor = texture2D(paletteMap, pos.st);
    
    gl_FragColor = pixelColor;
}

// Conversion between R-G-B and Y-Cr-Cb done with formulas from:
//   http://en.wikipedia.org/wiki/YCbCr#JPEG_conversion
//
// Color quantization in Y-Cr-Cb described at:
//   http://en.wikipedia.org/wiki/List_of_8-bit_computer_hardware_palettes#C-64