#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "av.hpp"

// http://bobobobo.wordpress.com/2008/02/11/opengl-in-a-proper-windows-app-no-glut/
// http://msdn2.microsoft.com/en-us/library/ms673957%28VS.85%29.aspx
// http://msdn2.microsoft.com/en-us/library/ms970745.aspx

#include <windows.h>
#include <math.h>
#include <gl/gl.h>
#include <gl/glu.h>

#pragma comment(lib, "opengl32.lib")
#pragma comment(lib, "glu32.lib")

HINSTANCE ghInstance;    // window app instance
HWND ghwnd;      // handle for the window
HDC   ghdc;      // handle to device context
HGLRC ghglrc;    // handle to OpenGL rendering context

int width = 800;
int height = 600;      

LRESULT CALLBACK WndProc( HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam );

void draw();            // drawing function containing OpenGL function calls

// entry point for a C++ Windows app:
int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR szCmdLine, int iCmdShow) {
	ghInstance = hInstance;
	
	// add a console:
	AllocConsole() ;
	AttachConsole( GetCurrentProcessId() ) ;
	// http://lua-users.org/lists/lua-l/1999-08/msg00001.html
	
	//HANDLE  Console = CreateConsoleScreenBuffer(GENERIC_READ|GENERIC_WRITE,0,0,CONSOLE_TEXTMODE_BUFFER,0);
	//SetConsoleActiveScreenBuffer(Console);
	//SetConsoleCtrlHandler((PHANDLER_ROUTINE)CtrlHandler, TRUE);
	SetConsoleTitle("av console");
	//As for repositioning the window, you can do a FindWindow on the caption "av
	//console" and then a SetWindowPos on the HWND you get back.  Not the most
	//elegant solution, but I doubt there's a better one.
	freopen("CON", "w", stdout) ;
    freopen("CON", "wt", stderr);
    freopen("CON", "rt", stdin);

	// create a window:
	WNDCLASS wc;
    wc.cbClsExtra = 0; 
    wc.cbWndExtra = 0; 
    wc.hbrBackground = (HBRUSH)GetStockObject( BLACK_BRUSH );
    wc.hCursor = LoadCursor( NULL, IDC_ARROW );         
    wc.hIcon = LoadIcon( NULL, IDI_APPLICATION );     
    wc.hInstance = hInstance;         
    wc.lpfnWndProc = WndProc;         
    wc.lpszClassName = TEXT("av");
    wc.lpszMenuName = 0; 
    wc.style = CS_HREDRAW | CS_VREDRAW | CS_OWNDC;
    // register with Windows:
    RegisterClass(&wc);
    
    // adjust window client area:
    RECT rect;
    SetRect( &rect, 50,  // left
                    50,  // top
                    width + 50, // right
                    height + 50 ); // bottom
    AdjustWindowRect( &rect, WS_OVERLAPPEDWINDOW, false );
    
    // create window:
    ghwnd = CreateWindow(TEXT("av"),
                          TEXT("av"),
                          WS_OVERLAPPEDWINDOW,
                          rect.left, rect.top,  // adjusted x, y positions
                          rect.right - rect.left, rect.bottom - rect.top,  // adjusted width and height
                          NULL, NULL,
                          hInstance, NULL);	
	if( ghwnd == NULL ) {
        FatalAppExit( NULL, TEXT("CreateWindow() failed!") );
    }
    ShowWindow( ghwnd, iCmdShow );
    
    // get device context:
    ghdc = GetDC( ghwnd );
    
    // set pixel format of window:
    // http://msdn2.microsoft.com/en-us/library/ms537556(VS.85).aspx
    PIXELFORMATDESCRIPTOR pfd = { 0 }; 
    pfd.nSize = sizeof( PIXELFORMATDESCRIPTOR );    // just its size
    pfd.nVersion = 1;   // always 1
    pfd.dwFlags = PFD_SUPPORT_OPENGL |  // OpenGL support - not DirectDraw
                  PFD_DOUBLEBUFFER   |  // double buffering support
                  PFD_DRAW_TO_WINDOW;   // draw to the app window, not to a bitmap image

    pfd.iPixelType = PFD_TYPE_RGBA ;    // red, green, blue, alpha for each pixel
    pfd.cColorBits = 24;                // 24 bit == 8 bits for red, 8 for green, 8 for blue.
    pfd.cDepthBits = 32;                // 32 bits to measure pixel depth
    // get best approximation of it:
    int chosenPixelFormat = ChoosePixelFormat( g.hdc, &pfd );
    if( chosenPixelFormat == 0 ) {
        FatalAppExit( NULL, TEXT("ChoosePixelFormat() failed!") );
    }
    // apply it:
    int result = SetPixelFormat( g.hdc, chosenPixelFormat, &pfd );
    if (result == NULL) {
        FatalAppExit( NULL, TEXT("SetPixelFormat() failed!") );
    }
    
    // create rendering context:
    ghglrc = wglCreateContext( ghdc );
    
    // connect with device:
    wglMakeCurrent( ghdc, ghglrc );
    
    ////////////////////////////////////////////////////////////////////////////
    
    // event loop:
    MSG msg;
    while( 1 ) {
        if( PeekMessage( &msg, NULL, 0, 0, PM_REMOVE ) ) {
            if( msg.message == WM_QUIT ) {
                break;
            }
            
            TranslateMessage( &msg );
            DispatchMessage( &msg );
        } else {
            
            // check for async keyboard input here
            
            glViewport(0, 0, width, height); 
            
            //6.  DRAW USING OPENGL.
            // This region right here is the
            // heart of our application.  THE MOST
            // execution time is spent just repeating
            // this draw() function.
            //draw();
            
            SwapBuffers(ghdc);
            
            // SLEEP()
        }
    }
    
    // cleanup:
    wglMakeCurrent( NULL, NULL );
    wglDeleteContext( ghglrc );
    ReleaseDC( ghwnd, ghdc );
    
    //CloseHandle(Console);
    FreeConsole();
    
    // cheesy fadeout
    AnimateWindow( ghwnd, 200, AW_HIDE | AW_BLEND );
    
    return msg.wParam;
}

LRESULT CALLBACK WndProc(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
    switch( message ) {
    case WM_CREATE:
        return 0;
        break;

    case WM_PAINT:
        {
            HDC hdc;
            PAINTSTRUCT ps;
            hdc = BeginPaint( hwnd, &ps );
                // don't draw here.  would be waaay too slow.
                // draw in the draw() function instead.
            EndPaint( hwnd, &ps );
        }
        return 0;
        break;

    case WM_KEYDOWN:
        /*
        switch( wparam ) {
        case VK_ESCAPE:
            PostQuitMessage( 0 );
            break;
        default:
            break;
        }
        */
        return 0;
        break;

    case WM_DESTROY:
        PostQuitMessage( 0 ) ;
        return 0;
        break;
    }
 
    return DefWindowProc( hwnd, message, wparam, lparam );
}