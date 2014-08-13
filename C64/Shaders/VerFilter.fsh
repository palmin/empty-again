varying mediump vec2 textureCoordinate;
precision mediump float;

uniform sampler2D videoFrame;
uniform float coefficient[3];
uniform float step;
uniform float offset;

void main() {
	/*vec4 sum =  
           coefficient[0] * texture2D(videoFrame, vec2(textureCoordinate.x, textureCoordinate.y - step));
    sum += coefficient[1] * texture2D(videoFrame, textureCoordinate);
    sum += coefficient[2] * texture2D(videoFrame, vec2(textureCoordinate.x, textureCoordinate.y + step));*/
            
	vec2 one = vec2(textureCoordinate.x, textureCoordinate.y - step);
	vec2 two = vec2(textureCoordinate.x, textureCoordinate.y);
	vec2 three = vec2(textureCoordinate.x, textureCoordinate.y + step);
	
    vec4 sum = coefficient[0] * texture2D(videoFrame, one) + 
               coefficient[1] * texture2D(videoFrame, two) + 
               coefficient[2] * texture2D(videoFrame, three);
	gl_FragColor = sum;
}
