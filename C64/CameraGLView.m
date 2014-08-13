//
//  ColorTrackingGLView.m
//  ColorTracking
//
//
//  The source code for this application is available under a BSD license.  See License.txt for details.
//
//  Created by Brad Larson on 10/7/2010.
//

#import "CameraGLView.h"
#import <OpenGLES/EAGLDrawable.h>
#import <QuartzCore/QuartzCore.h>

@implementation CameraGLView

// Override the class method to return the OpenGL layer, as opposed to the normal CALayer
+ (Class) layerClass {
	return [CAEAGLLayer class];
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) 
	{
		// Do OpenGL Core Animation layer setup
		CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
		
		// Set scaling to account for Retina display	
//		if ([self respondsToSelector:@selector(setContentScaleFactor:)])
//		{
//			self.contentScaleFactor = [[UIScreen mainScreen] scale];
//		}
		
		eaglLayer.opaque = YES;
		eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];		
		context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
		
		if (!context || ![EAGLContext setCurrentContext:context] || ![self createFramebuffers]) 
		{
			return nil;
		}
		
        // Initialization code
    }
    return self;
}

-(UIImage *) imageGrab {
    int w = self.bounds.size.width, h = self.bounds.size.height;
    
    unsigned char* buffer = malloc(w*h*4);
    glReadPixels(0,0,w,h,GL_RGBA, GL_UNSIGNED_BYTE, buffer);
    CGDataProviderRef ref = CGDataProviderCreateWithData(NULL, buffer, w*h*4, NULL);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef iref = CGImageCreate(w,h,8,32,w*4,colorSpace,
                                    kCGBitmapByteOrderDefault,ref,NULL,true,kCGRenderingIntentDefault);
    
    CGContextRef ctx = CGBitmapContextCreate(NULL, w, h, 8, w*4, colorSpace, 
                                             kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Big);
    CGContextTranslateCTM(ctx, 0.0, h);
    CGContextScaleCTM(ctx, 1.0, -1.0);
    CGContextDrawImage(ctx, CGRectMake(0.0, 0.0, w, h), iref);
    
    CGImageRef outputRef = CGBitmapContextCreateImage(ctx);
    UIImage *outputImage = [UIImage imageWithCGImage:outputRef];
    
    CGImageRelease(outputRef);
    CGImageRelease(iref);
    CGDataProviderRelease(ref);
    CGContextRelease(ctx);
    free(buffer);
    CGColorSpaceRelease(colorSpace);

    return outputImage;
}

#pragma mark OpenGL drawing

- (BOOL)createFramebuffers {	
	glEnable(GL_TEXTURE_2D);
	glDisable(GL_DEPTH_TEST);

	// Onscreen framebuffer object
	glGenFramebuffers(1, &viewFramebuffer);
	glBindFramebuffer(GL_FRAMEBUFFER, viewFramebuffer);
	
	glGenRenderbuffers(1, &viewRenderbuffer);
	glBindRenderbuffer(GL_RENDERBUFFER, viewRenderbuffer);
	
	[context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
	
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
	
	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, viewRenderbuffer);
	
	if(glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) 
	{
		NSLog(@"Failure with framebuffer generation");
		return NO;
	}
	
	return YES;
}

- (void)destroyFramebuffer {	
	if (viewFramebuffer)
	{
		glDeleteFramebuffers(1, &viewFramebuffer);
		viewFramebuffer = 0;
	}
	
	if (viewRenderbuffer)
	{
		glDeleteRenderbuffers(1, &viewRenderbuffer);
		viewRenderbuffer = 0;
	}
}

- (void)setDisplayFramebuffer {
    if (context) {
//        [EAGLContext setCurrentContext:context];
        
        if (!viewFramebuffer)
		{
            [self createFramebuffers];
		}
        
        glBindFramebuffer(GL_FRAMEBUFFER, viewFramebuffer);        
        glViewport(0, 0, backingWidth, backingHeight);
    }
}

- (BOOL)presentFramebuffer {
    BOOL success = FALSE;
    
    if (context) {
  //      [EAGLContext setCurrentContext:context];
        
        glBindRenderbuffer(GL_RENDERBUFFER, viewRenderbuffer);
        
        success = [context presentRenderbuffer:GL_RENDERBUFFER];
    }
    
    return success;
}

@end
