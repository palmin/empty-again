varying mediump vec2 textureCoordinate;
precision mediump float;

uniform sampler2D videoFrame;
uniform sampler2D outputFrame;
uniform float coefficient[3];
uniform float step;

void main() {
	/*vec4 sum = coefficient[0] * texture2D(videoFrame, vec2(textureCoordinate.x - step,					
														   textureCoordinate.y));
		 sum += coefficient[1] * texture2D(videoFrame, textureCoordinate);
	     sum += coefficient[2] * texture2D(videoFrame, vec2(textureCoordinate.x + step, 
															textureCoordinate.y));*/

	// y[n] = (  1 * x[n- 2])
    //      + (  2 * x[n- 1])
    //      + (  1 * x[n- 0])
    //      + ( -0.5740619151 * y[n- 2])
    //      + (  1.4542435863 * y[n- 1])
	
	vec2 two = vec2(textureCoordinate.x - 2.0 * step, textureCoordinate.y);
	vec2 one = vec2(textureCoordinate.x - step, textureCoordinate.y);
    vec2 now = textureCoordinate;
	
	vec4 sum = coefficient[0] * texture2D(videoFrame, one) + 
	           coefficient[1] * texture2D(videoFrame, now) + 
	           coefficient[2] * texture2D(outputFrame, one);
	gl_FragColor = sum;
}
