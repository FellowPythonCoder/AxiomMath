#include <stdlib.h>
#include <stdio.h>
#include <time.h>

__attribute__((visibility("default"))) 
void get_fast_math(int grade, char* q_buf, int q_size, char* a_buf, int a_size) {
    static int seeded = 0;
    if (!seeded) {
        srand((unsigned int)time(NULL));
        seeded = 1;
    }

    int a = rand() % 10 + 2;
    int b = rand() % 10 + 2;

    if (grade <= 3) {
        snprintf(q_buf, q_size, "%d + %d", a, b);
        snprintf(a_buf, a_size, "%d", a + b);
    } else if (grade <= 6) {
        snprintf(q_buf, q_size, "%d x %d", a, b);
        snprintf(a_buf, a_size, "%d", a * b);
    } else if (grade <= 9) {

        int c = a * b + b;
        snprintf(q_buf, q_size, "%dx + %d = %d", a, b, c);
        snprintf(a_buf, a_size, "%d", (c - b) / a);
    } else {

        int r1 = rand() % 5 + 1;
        int r2 = -(rand() % 5 + 1); 
        int b_quad = -(r1 + r2);
        int c_quad = r1 * r2;
        snprintf(q_buf, q_size, "x^2 + %dx + %d = 0 (Find positive root)", b_quad, c_quad);
        snprintf(a_buf, a_size, "%d", r1);
    }
}