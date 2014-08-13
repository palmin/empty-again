varying mediump vec2 textureCoordinate;
precision mediump float;

uniform sampler2D videoFrame;

void main() {
	gl_FragColor = texture2D(videoFrame, textureCoordinate.st);
}