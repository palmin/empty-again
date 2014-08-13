//
//  ColorTrackingCamera.h
//  ColorTracking
//
//
//  The source code for this application is available under a BSD license.  See License.txt for details.
//
//  Created by Brad Larson on 10/9/2010.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>

@protocol CameraDelegate;

@interface Camera : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate>
{
	AVCaptureVideoPreviewLayer *videoPreviewLayer;
	AVCaptureSession *captureSession;
	AVCaptureDeviceInput *videoInput;
	AVCaptureVideoDataOutput *videoOutput;
    
    BOOL highQuality, canFlip, frontFacing;
}

@property(nonatomic, assign) id<CameraDelegate> delegate;
@property(readonly) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (readonly) BOOL canFlip;

// will return TRUE if quality changed
-(BOOL)setHighQuality:(BOOL)highQuality;
-(void)start;
-(void)stop;

-(void)flipCamera;

@end

@protocol CameraDelegate
- (void)cameraHasConnected;
- (void)processNewCameraFrame:(CVImageBufferRef)cameraFrame;
@end
