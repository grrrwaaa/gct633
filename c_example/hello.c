
// to compile this program:
// cc hello.c -o hello
// to run it:
// ./hello

// #include directives tell the compiler to load in additional "header" files
// these files declare additional functions we can use
// we need <stdio.h> in order to use printf() below
#include <stdio.h>

// the "main" function is where the program starts running
int main() {
	// printf puts text onto the output console
	// we need to add \n so that it outputs the line break at the end
    printf("hello, world\n");
    
    // main must return an integer
    // (the value indicates whether the program succeeded or had an error)
    // (returning zero means no error occurred)
    return 0;
}
