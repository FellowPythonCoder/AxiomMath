//
//  generator.c
//  Axiom
//
//  Created by azad pelia on 7/28/26.
//
#include <stdlib.h>
#include <time.h>

// Generates a random number between min and max (inclusive)
int generate_random(int min, int max) {
    static int seeded = 0;
    if (!seeded) {
        
        srand((unsigned int)time(NULL));
        seeded = 1;
    }
    return rand() % (max - min + 1) + min;
}
