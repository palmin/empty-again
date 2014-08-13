varying mediump vec2 textureCoordinate;
precision mediump float;

uniform sampler2D videoFrame;
uniform sampler2D ditherMap;

void main() {
    vec4 pixelColor;
    vec3 YCrCb;
    
	pixelColor = texture2D(videoFrame, textureCoordinate.st);
    pixelColor = pixelColor + texture2D(ditherMap, textureCoordinate.st) - 0.5;
    
    YCrCb = vec3(    0.299 * pixelColor.r +    0.587 * pixelColor.g +    0.114 * pixelColor.b,
                 -0.168736 * pixelColor.r - 0.331264 * pixelColor.g +      0.5 * pixelColor.b,
                       0.5 * pixelColor.r - 0.418688 * pixelColor.g - 0.081313 * pixelColor.b);
    
    YCrCb[0] = floor(0.499 + YCrCb[0] * 5.0) / 5.0;
    YCrCb[1] = floor(0.499 + YCrCb[1] * 3.0) / 3.0;
    YCrCb[2] = floor(0.499 + YCrCb[2] * 3.0) / 3.0;
    
    pixelColor = vec4(YCrCb[0]                        + 1.402 * YCrCb[2],
                      YCrCb[0] - 0.34414 * YCrCb[1] - 0.71414 * YCrCb[2],
                      YCrCb[0] +   1.772 * YCrCb[1],
                      pixelColor.a);
    
    gl_FragColor = pixelColor;
}

// Conversion between R-G-B and Y-Cr-Cb done with formulas from:
//   http://en.wikipedia.org/wiki/YCbCr#JPEG_conversion
//
// Color quantization in Y-Cr-Cb described at:
//   http://en.wikipedia.org/wiki/List_of_8-bit_computer_hardware_palettes#C-64