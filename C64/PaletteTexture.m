//
//  PaletteTexture.m
//  C64
//
//  Created by Anders Borum on 19/08/14.
//  Copyright (c) 2014 Applied Phasor. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "PaletteTexture.h"

@implementation PaletteTexture

// data is returned as RGBA8888 and must be freed
+(unsigned char*)newRGBAsFromImage:(UIImage*)image {
    // First get the image into your data buffer
    CGImageRef imageRef = [image CGImage];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = (unsigned char*) calloc(height * width * 4, sizeof(unsigned char));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    
    return rawData;
}

static void freeData(void *info, const void *data, size_t size) {
    free((void*)data);
}

// rgba blongs to image after this call
CGImageRef newIgImagefromPixels(unsigned char* rgba, int wid, int hei) {
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, rgba, wid*hei*4, freeData);
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
    CGImageRef image = CGImageCreate(wid,hei,8,32,4*wid,colorSpaceRef,
                                     bitmapInfo,provider,NULL,NO,renderingIntent);
    CGColorSpaceRelease(colorSpaceRef);

    return image;
}

// transfer 4 bytes from source to destination
static inline void transfer(unsigned char const* source, size_t sourceIndex,
                            unsigned char* destination, size_t destIndex) {
    destination[4 * destIndex + 0] = source[4 * sourceIndex + 0];
    destination[4 * destIndex + 1] = source[4 * sourceIndex + 1];
    destination[4 * destIndex + 2] = source[4 * sourceIndex + 2];
    destination[4 * destIndex + 3] = source[4 * sourceIndex + 3];
}

// reorder image defining palette reduction (16 pixels wide, 16 x 17 pixels heigh) into
// 64 x 64 image.
+(GLKTextureInfo*)textureFromImage:(UIImage*)image {
    /*NSUInteger wid = image.size.width, hei = image.size.height;
    if(wid != 16 || hei != 17 * 16) return nil;
    
    unsigned char* input = [PaletteTexture newRGBAsFromImage: image];
    unsigned char* output = malloc(4 * 64 * 64);
    
    for(int blue = 0; blue <= 15; ++blue) {
        for(int green = 0; green <= 15; ++green) {
            for(int red = 0; red <= 15; ++red) {
            
                int inX = red, inY = 17 * blue + green;
                int outX = red + ((green & 3) << 4), outY = (green >> 2) | (blue << 2);
                NSLog(@"rgb = %d,%d,%d x,y=%d,%d", red, green, blue, outX, outY);
                
                transfer(input, wid * inY + inX, output, 64 * outY + outX);
            }
        }
    }
    free(input);
    
    CGImageRef cgImage = newIgImagefromPixels(output, 64, 64);
#ifdef DEBUG
    UIImage* _image = [UIImage imageWithCGImage:cgImage];
    NSData* png = UIImagePNGRepresentation(_image);
    [png writeToFile:@"/Users/ander/Desktop/pal-out.png" atomically:NO];
#endif
     */
    
    NSError* error = nil;
    GLKTextureInfo* texture = [GLKTextureLoader textureWithCGImage:image.CGImage options:nil error:&error];
    if(!texture) {
        NSLog(@"Unable to load palette texture: %@", error);
        return nil;
    }

    return texture;
}

@end
