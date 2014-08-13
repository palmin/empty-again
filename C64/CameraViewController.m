//
//  ColorTrackingViewController.m
//  ColorTracking
//
//
//  The source code for this application is available under a BSD license.  See License.txt for details.
//
//  Created by Brad Larson on 10/7/2010.
//

#import "CameraViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import <GLKit/GLKit.h>

// Uniform index.
enum {
    UNIFORM_VIDEOFRAME,
	UNIFORM_INPUTCOLOR,
	UNIFORM_THRESHOLD,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum {
    ATTRIB_VERTEX,
    ATTRIB_TEXTUREPOSITON,
    NUM_ATTRIBUTES
};

@implementation CameraViewController

#define DEBUG

#pragma mark -
#pragma mark Initialization and teardown

-(void)setupAudio {
    NSBundle* bundle = [NSBundle mainBundle];
    NSURL* url = [bundle URLForResource:@"shutter" withExtension:@"caf"];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &shutterSoundID);
}

-(void)teardownAudio {
    AudioServicesDisposeSystemSoundID(shutterSoundID);
}

-(void)playShutterSound {
    AudioServicesPlaySystemSound(shutterSoundID);
}

-(void)setup {
    displayMode = PASSTHROUGH_VIDEO;
    [self setupAudio];
}

-(id)initWithScreen:(UIScreen *)newScreenForDisplay {
    if ((self = [super initWithNibName:nil bundle:nil])) {
		screenForDisplay = newScreenForDisplay;
        [self setup];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self) {
        screenForDisplay = [UIScreen mainScreen];
        [self setup];
    }
    return self;
}

-(void)setupTexturesWithSize:(CGSize)size {
    if(m_setup) return;
    
    //NSLog(@"textures are sized %dx%d", (int)size.width, (int)size.height);
    
    if(m_hTexture == NULL) {
        m_hTexture = malloc(sizeof(m_hTexture[0]) * numTextureSteps);
    }
    glGenTextures(numTextureSteps, m_hTexture);
    
    for (int Index = 0; Index < numTextureSteps; Index++) {
        // Bind and configure each texture
        glBindTexture(GL_TEXTURE_2D, m_hTexture[Index]);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, size.width, size.height, 0, GL_RGB, GL_UNSIGNED_BYTE, 0);
        
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    }
    
    // Generate handles for two Frame Buffer Objects
    if(m_hFBO == NULL) {
        m_hFBO = malloc(sizeof(m_hFBO[0]) * numTextureSteps);
    }
    glGenFramebuffers(numTextureSteps, m_hFBO);
    
    for (int Index = 0; Index < numTextureSteps; Index++)
    {
        // Attach each texture to the first color buffer of an FBO and clear it
        glBindFramebuffer(GL_FRAMEBUFFER, m_hFBO[Index]);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, m_hTexture[Index], 0);
        glClear(GL_COLOR_BUFFER_BIT);
    }

    m_setup = TRUE;
}

-(void)releaseTextures {
    if(!m_setup) return;
    
    if(m_hFBO != NULL) {
        glDeleteFramebuffers(numTextureSteps, m_hFBO);
        free(m_hFBO);
        m_hFBO = NULL;
    }

    if(m_hTexture != NULL) {
        glDeleteTextures(numTextureSteps, m_hTexture);
        free(m_hTexture);
        m_hTexture = NULL;
    }
    
    m_setup = FALSE;
}

-(void)loadDitherMap {
    if(ditherTexture) return;
    
    NSLog(@"GL Error = %u", glGetError());
    
    NSError* error = nil;
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"dither" ofType:@"png"];
    UIImage* image = [UIImage imageWithContentsOfFile:filePath];
    ditherTexture = [GLKTextureLoader textureWithCGImage:image.CGImage options:nil error:&error];
    if(!ditherTexture) {
        NSLog(@"Unable to load %@:\n%@", filePath, error);
        return;
    }
    
    glBindTexture(ditherTexture.target, ditherTexture.name);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glEnable(ditherTexture.target);
}

- (void)setupToolbar: (CGRect) frame  {
    // Set up the toolbar at the bottom of the screen
      CGRect sliderRect = CGRectMake(0, 0, frame.size.width - 20, 44);
    sliderControl = [[UISlider alloc] initWithFrame:sliderRect];
    sliderControl.minimumValue = 1;
    sliderControl.value = weeks;
    sliderControl.maximumValue = 52;
    sliderControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [sliderControl addTarget:self action:@selector(sliderChanged) 
            forControlEvents:UIControlEventValueChanged];
	UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:sliderControl];
    
    UIImage* ageImage = [UIImage imageNamed:@"menu_icon_baby.png"];
    UIBarButtonItem* ageButton = [[UIBarButtonItem alloc] 
                                  initWithImage:ageImage style: UIBarButtonItemStylePlain 
                                                        target:self action:@selector(startConfig)];
    
    // flex item used to separate the left groups items and right grouped items
	UIBarButtonItem *flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                              target:nil action:nil];
    
    UIImage* photoImage = [UIImage imageNamed:@"menu_icon_camera.png"];
    UIBarButtonItem* photoButton = [[UIBarButtonItem alloc] 
                                  initWithImage:photoImage style: UIBarButtonItemStylePlain 
                                  target:self action:@selector(requestPhoto)];
	
    // flex item used to separate the left groups items and right grouped items
	UIBarButtonItem *flexItem2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
																			   target:nil action:nil];

	UIBarButtonItem* flipButton = nil;
	if(camera.canFlip) {
		UIImage* flipImage = [UIImage imageNamed:@"menu_icon_switch.png"];
		flipButton = [[UIBarButtonItem alloc] initWithImage:flipImage style: UIBarButtonItemStylePlain 
													 target:self action:@selector(flipCamera)];
	}
    
    // debug buttons to directly adjust age
    //UIBarButtonItem* olderButton = [[[UIBarButtonItem alloc] initWithTitle:@"++" style:UIBarButtonItemStylePlain 
    //                                                                target:self action:@selector(older)] autorelease];
    //UIBarButtonItem* youngerButton = [[[UIBarButtonItem alloc] initWithTitle:@"--" style:UIBarButtonItemStylePlain 
    //                                                                target:self action:@selector(younger)] autorelease];
    
	
    NSArray *theToolbarItems = [NSArray arrayWithObjects:ageButton, flexItem, 
								photoButton, flexItem2, flipButton, /*flexItem2, youngerButton, olderButton,*/ nil];
	
	lowerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, self.view.frame.size.height - 44.0f, self.view.frame.size.width, 44.0f)];
	lowerToolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	lowerToolbar.tintColor = [UIColor blackColor];
    lowerToolbar.alpha = 0.5;
	
	[lowerToolbar setItems:theToolbarItems];
	[self.view addSubview:lowerToolbar];
}

-(void)setNumTextureSteps:(int)steps {
    if(numTextureSteps == steps) return;
    
    [self releaseTextures];
    numTextureSteps = steps;
}

- (void)loadView {
    self.title = @"View";
    numTextureSteps = 6;
	
	/*CGRect applicationFrame = [screenForDisplay applicationFrame];	
	NSLog(@"appFrame sized %dx%d with offset %dx%d", (int)applicationFrame.size.width, 
          (int)applicationFrame.size.height, (int)applicationFrame.origin.x, 
          (int)applicationFrame.origin.y);*/
    
    CGRect mainScreenFrame = [[UIScreen mainScreen] applicationFrame];	
	UIView *primaryView = [[UIView alloc] initWithFrame:mainScreenFrame];
	self.view = primaryView;
	
    CGRect frame = {CGPointZero, CGSizeMake(360, 480)};
	glView = [[CameraGLView alloc] initWithFrame:frame];	
	[self.view addSubview:glView];
    
    [self loadDitherMap];

    if(!programLoaded) {		
		[self loadFilterShader:@"Shader" fragmentShader:@"C64" forProgram:&c64FilterProgram];
        colorFilterFrame = glGetUniformLocation(c64FilterProgram, "videoFrame");
        ditherMap = glGetUniformLocation(c64FilterProgram, "ditherMap");
	
		programLoaded = TRUE;
	}

    overlay = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"vignet"]];
    [self.view addSubview:overlay];

	displayMode = 1;
	
    //debugLabel = [[UILabel alloc] initWithFrame:CGRectMake(3, 3, 100, 30)];
    //debugLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
    //debugLabel.textColor = [UIColor colorWithWhite:1 alpha:0.9];
    //[self.view addSubview:debugLabel];
    //[debugLabel release];
    		
	NSMutableDictionary *newActions = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNull null], @"position",
									   nil];
		
    // add view controller that detects taps to show or hide toolbar
    /*UITapGestureRecognizer* tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    [self.view addGestureRecognizer:tapRecognizer];
    [tapRecognizer release];*/
    
	camera = [[Camera alloc] init];
	camera.delegate = self;
		
	[self setupToolbar: frame];
	[self cameraHasConnected];
}

- (void)dealloc {
    [self teardownAudio];
    [hideTimer invalidate];
    
    [self releaseTextures];
}

-(void)viewWillAppear:(BOOL)animated {
    [self setWeeks:10];
    [self showToolbar:animated];
    
    [self.navigationController setNavigationBarHidden:TRUE animated:animated];
    [super viewWillAppear:animated];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self showToolbar: FALSE];

    // we go directly to birthday entry, if none is set
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults]; 
    NSDate* date = [defaults objectForKey:@"birthday"];
    if(date == nil) [self startConfig];
    
    overlay.image = nil;
    pauseFilter = FALSE;
    [camera start];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    pauseFilter = TRUE;
    [camera stop];
}

#pragma mark -

-(void)sliderChanged {
    double w = sliderControl.value;
    [self setWeeks:w];
}

-(void)requestPhoto {
    [self playShutterSound];
    grabNextPicture = TRUE;
}

-(void)savePhoto {
    UIImageWriteToSavedPhotosAlbum(grabbedImage, self, nil, NULL);
}

-(void)sharePhoto {
}

-(void)handlePhoto {    
    overlay.image = grabbedImage;
    [self neverHideToolbar];
    
    UIActionSheet* sheet = [[UIActionSheet alloc] initWithTitle:@"" delegate:self 
                                              cancelButtonTitle:@"Back" destructiveButtonTitle:nil 
                                              otherButtonTitles:@"Share", @"Save", nil];
    
    [sheet showInView:self.view];
}

-(void)grabDone {
    [self showToolbar:FALSE];
    overlay.image = [UIImage imageNamed:@"vignet"];
    grabbedImage = nil;
    pauseFilter = FALSE;
    [camera start];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSInteger index = buttonIndex - actionSheet.firstOtherButtonIndex;
    switch(index) {
        case 0:
            [self sharePhoto];
            break;
        case 1:
            [self savePhoto];
            [self grabDone];
            break;

        default:
            [self grabDone];
            break;
    }
}

- (void)actionSheetCancel:(UIActionSheet *)actionSheet {
    [self grabDone];
}

-(void)startConfig {
}

-(void)setWeeks:(float)w {   
    if((int)(100.0 * weeks) == (int)(100.0 * w)) return;
    
    overlay.alpha = 0.0;
    
    BOOL highresInput = NO;

    if([camera setHighQuality: highresInput]) {
        [self releaseTextures];
    }
    
    weeks = w;
    //debugLabel.text = [NSString stringWithFormat:@"%.1f", weeks];
}

#pragma mark OpenGL ES 2.0 rendering methods

void drawSquare(void) {
    static const GLfloat squareVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    
	static const GLfloat textureVertices[] = {
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f,  1.0f,
        0.0f,  0.0f,
    };
	glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, squareVertices);
	glEnableVertexAttribArray(ATTRIB_VERTEX);
	glVertexAttribPointer(ATTRIB_TEXTUREPOSITON, 2, GL_FLOAT, 0, 0, textureVertices);
	glEnableVertexAttribArray(ATTRIB_TEXTUREPOSITON);
	
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

-(void)drawTextureWithIndex:(int)index {
    glBindFramebuffer(GL_FRAMEBUFFER, m_hFBO[index]);
    
    // FBO attachment is complete?
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE)
    {
        // Set viewport to size of texture map and erase previous image
        glViewport(0, 0, bufferWidth, bufferHeight);
        glClearColor(0.8f, 0.8f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
        drawSquare();
    }
    
    // bind output texture to make it input for next draw-step
    glBindTexture(GL_TEXTURE_2D, m_hTexture[index]);
}

- (void)drawFrame {        
	glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, videoFrameTexture);
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, ditherTexture.name);
    
    glUseProgram(c64FilterProgram);
    
    // color filter output goes to screen
    glBindFramebuffer(GL_FRAMEBUFFER, 0);    
	[glView setDisplayFramebuffer];

    drawSquare();    
    
    if(grabNextPicture) {
        grabNextPicture = FALSE;
        pauseFilter = TRUE;
        
        UIImage* image = [glView imageGrab];
        grabbedImage = image;
        [self performSelector:@selector(handlePhoto) withObject:nil afterDelay:0.01];
    }
    
    [glView presentFramebuffer];
}

#pragma mark -
#pragma mark OpenGL ES 2.0 setup methods

- (BOOL)loadFilterShader:(NSString *)vertexShaderName 
          fragmentShader:(NSString *)fragmentShaderName 
              forProgram:(GLuint *)programPointer {   
    GLuint vertexShader, fragShader;
	
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    *programPointer = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:vertexShaderName ofType:@"vsh"];
    if (![self compileShader:&vertexShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return FALSE;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:fragmentShaderName ofType:@"fsh"];
	if(fragShaderPathname == nil) {
		NSLog(@"Unable to find path for %@.fsh", fragmentShaderName); 
	}
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return FALSE;
    }
    
    // Attach vertex shader to program.
    glAttachShader(*programPointer, vertexShader);
    
    // Attach fragment shader to program.
    glAttachShader(*programPointer, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(*programPointer, ATTRIB_VERTEX, "position");
    glBindAttribLocation(*programPointer, ATTRIB_TEXTUREPOSITON, "inputTextureCoordinate");
    
    // Link program.
    if (![self linkProgram:*programPointer]) {
        NSLog(@"Failed to link program: %d", *programPointer);
        
        if (vertexShader) {
            glDeleteShader(vertexShader);
            vertexShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (*programPointer) {
            glDeleteProgram(*programPointer);
            *programPointer = 0;
        }
        
        return FALSE;
    }
        
    // Release vertex and fragment shaders.
    if (vertexShader) {
        glDeleteShader(vertexShader);
	}
    if (fragShader) {
        glDeleteShader(fragShader);		
	}
    
    return TRUE;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file {
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source)
    {
        NSLog(@"Unable to load vertex shader");
        return FALSE;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0)
    {
        glDeleteShader(*shader);
        return FALSE;
    }
    
    return TRUE;
}

- (BOOL)linkProgram:(GLuint)prog {
    GLint status;
    
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0)
        return FALSE;
    
    return TRUE;
}

- (BOOL)validateProgram:(GLuint)prog {
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0)
        return FALSE;
    
    return TRUE;
}

#pragma mark -
#pragma mark Display mode switching

-(void)sliderChanged:(id)sender {
	UISlider* slider = sender;
	weekNum = slider.value;
	weekNumChanged = TRUE;
}

- (void)handleSwitchOfDisplayMode:(id)sender;
{
	displayMode = [sender selectedSegmentIndex];
}

- (void)cameraHasConnected; {
	//NSLog(@"We have connection!");
/*	camera.videoPreviewLayer.frame = self.view.bounds;
	[self.view.layer addSublayer:camera.videoPreviewLayer];*/
}

- (void)processNewCameraFrame:(CVImageBufferRef)cameraFrame {
    if(pauseFilter) return;
    
	CVPixelBufferLockBaseAddress(cameraFrame, 0);
	bufferHeight = CVPixelBufferGetHeight(cameraFrame);
	bufferWidth = CVPixelBufferGetWidth(cameraFrame);
	
    [self setupTexturesWithSize:CGSizeMake(bufferWidth, bufferHeight)];
    
	// Create a new texture from the camera frame data, display that using the shaders
	glGenTextures(1, &videoFrameTexture);
	glBindTexture(GL_TEXTURE_2D, videoFrameTexture);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	
	// This is necessary for non-power-of-two textures
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	
	// Using BGRA extension to pull in video frame data directly
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, bufferWidth, bufferHeight, 0, 
				 GL_BGRA, GL_UNSIGNED_BYTE, CVPixelBufferGetBaseAddress(cameraFrame));

	[self drawFrame];
	
	glDeleteTextures(1, &videoFrameTexture);
	CVPixelBufferUnlockBaseAddress(cameraFrame, 0);
    
    NSTimeInterval time = [NSDate timeIntervalSinceReferenceDate];
    //debugLabel.text = [NSString stringWithFormat: @"%.1f %d", weeks, (int)(1.0 / (time - lastTime))];
    lastTime = time;
}

-(void)neverHideToolbar {
    [hideTimer invalidate]; hideTimer = nil;
}

-(void)showToolbar:(BOOL)animated {
    toolbarShown = TRUE;   
    
    if(animated) {
        [UIView animateWithDuration:0.2 animations:^{
            lowerToolbar.alpha = 1;
        }];
    } else {
        lowerToolbar.alpha = 1;
    }
    
    // schedule timer to hide toolbar
    if(hideInvocation == nil) {
        NSMethodSignature* signature = [CameraViewController instanceMethodSignatureForSelector:@selector(hideToolbarSlowly)];
        hideInvocation = [NSInvocation invocationWithMethodSignature:signature];
        [hideInvocation setTarget:self];
        [hideInvocation setSelector:@selector(hideToolbarSlowly)];
    }
    [self neverHideToolbar];
    hideTimer = [NSTimer scheduledTimerWithTimeInterval:5 invocation:hideInvocation
                                                repeats:FALSE];
}

-(void)hideToolbar:(NSNumber*)duration {
    toolbarShown = FALSE;
    
    [UIView animateWithDuration:[duration doubleValue] animations:^{
        lowerToolbar.alpha = 0;
    }];
}

-(void)hideToolbarSlowly {
    [self hideToolbar: [NSNumber numberWithDouble:1]];
}

-(void)flipCamera {
	[camera flipCamera];
    [self showToolbar:FALSE];
}

-(void)older {
    [self setWeeks:weeks + 1.0];
    [self showToolbar:FALSE];
}

-(void)younger {
    if(weeks >= 0.2) {
        [self setWeeks:weeks - 1.0];
    }
    [self showToolbar:FALSE];
}

/*- (void)tap:(UIGestureRecognizer *)gestureRecognizer {
    if(gestureRecognizer.state != UIGestureRecognizerStateRecognized) return;
    
    if(toolbarShown) [self hideToolbar: [NSNumber numberWithDouble:0.2]];
    else [self showToolbar: TRUE];
}*/

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if(toolbarShown) {
        CGPoint point = [[touches anyObject] locationInView:self.view]; 
        double yRatio = point.y / self.view.bounds.size.height;
        if(yRatio <= 0.8) {
            [self hideToolbar: [NSNumber numberWithDouble:0.2]];
        }
    }
    else {
        [self showToolbar: TRUE];
    }
}

#pragma mark -
#pragma mark Accessors

@synthesize glView;

@end
