//
//  main.m
//  mk-palette
//
//  Created by Anders Borum on 18/08/14.
//  Copyright (c) 2014 Applied Phasor. All rights reserved.
//

#include <stdio.h>

static void calc(int x, int y, int* red, int* green, int* blue) {
    *red = x % 17;
    *green = y % 17;
    *blue = (x / 17) + 4 * (y / 17);
    
    if(*red == 16 || *green == 16) {
        *red = *green = *blue = 0;
    }
}

int main(int argc, const char * argv[]) {
    // insert code here...
    int width = 4 * 17, height = 4 * 17;
    printf("P3\n%d %d\n15\n", width, height);
    for(int y = 0; y < height; ++y) {
        for(int x = 0; x < width; ++x) {
            int red, green, blue;
            calc(x, y, &red, &green, &blue);
            printf("%d %d %d ", red, green, blue);
        }
        printf("\n");
    }

    return 0;
}
