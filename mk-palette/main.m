//
//  main.m
//  mk-palette
//
//  Created by Anders Borum on 18/08/14.
//  Copyright (c) 2014 Applied Phasor. All rights reserved.
//

#include <stdlib.h>

int main(int argc, const char * argv[]) {
        // insert code here...
	    int height = 16 * (1 + 16);
        printf("P3\n16 %d\n15\n", height);
        for(int blue = 0; blue <= 15; ++blue) {
            for(int green = 0; green <= 15; ++green) {
                for(int red = 0; red <= 15; ++red) {
                    printf("%d %d %d ", red, green, blue);
                }
                printf("\n");
            }
            
            // end with empty line
            for(int k = 0; k <= 15; ++k) {
                printf("0 0 0 ");
            }
            printf("\n");
        }
    return 0;
}
