//
//  PaletteTexture.h
//  C64
//
//  Created by Anders Borum on 19/08/14.
//  Copyright (c) 2014 Applied Phasor. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PaletteTexture : NSObject

+(GLKTextureInfo*)textureFromImage:(UIImage*)image;

@end
