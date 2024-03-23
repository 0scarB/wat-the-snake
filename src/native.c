#include <stdint.h>
#include <stdio.h>
#include <stdio.h>
#include <GLFW/glfw3.h>
#include "snake.h"

#define MAX_CANVAS_WIDTH 960
#define MAX_CANVAS_HEIGHT 1024

typedef struct w2c_imports {
    wasm_rt_memory_t memory;
} w2c_imports;

w2c_snake wasm_module;
w2c_imports wasm_imports;

int canvas_width = 0;
int canvas_height = 0;
int canvas_x_offset = 0;
int canvas_y_offset = 0;
float canvas_scale_x = 1.0;
float canvas_scale_y = 1.0;
bool mouse_is_down = false;

static void glfw_error_callback(
        int error,
        const char* description
) {
    fprintf(stderr, "[GLFW ERROR] %s\n", description);
}

static void handle_key_action(
        GLFWwindow* window, 
        int key, int scancode, int action, int mods
) {
    u32 input_type;
    switch (action) {
        case GLFW_PRESS:
            input_type = *w2c_snake_INPUT_START(&wasm_module);
            break;
        case GLFW_RELEASE:
            input_type = *w2c_snake_INPUT_END(&wasm_module);
            break;
        default:
            return;
    }

    u32 wasm_key = key;
    switch (key) {
        case GLFW_KEY_UP:
            wasm_key = *w2c_snake_ARROW_UP(&wasm_module);
            break;
        case GLFW_KEY_LEFT:
            wasm_key = *w2c_snake_ARROW_LEFT(&wasm_module);
            break;
        case GLFW_KEY_DOWN:
            wasm_key = *w2c_snake_ARROW_DOWN(&wasm_module);
            break;
        case GLFW_KEY_RIGHT:
            wasm_key = *w2c_snake_ARROW_RIGHT(&wasm_module);
            break;
    }

    w2c_snake_input_key(&wasm_module, input_type, wasm_key);
}

static void handle_mouse_button(
        GLFWwindow* window, int button, int action, int mods
) {
    if (button != GLFW_MOUSE_BUTTON_LEFT) {
        return;
    }

    switch (action) {
        case GLFW_PRESS:
            mouse_is_down = true;
            break;
        case GLFW_RELEASE:
            mouse_is_down = false;
            break;
    }

    if (!mouse_is_down) {
        return;
    }

    double x, y;
    glfwGetCursorPos(window, &x, &y);
    w2c_snake_input_touch(
            &wasm_module,
            *w2c_snake_INPUT_START(&wasm_module),
            (x/canvas_scale_x) - canvas_x_offset,
            (y/canvas_scale_y) - canvas_y_offset);
}

static void handle_cursor_position(GLFWwindow* window, double x, double y) {
    if (!mouse_is_down) {
        return;
    }

    w2c_snake_input_touch(
            &wasm_module,
            *w2c_snake_INPUT_UPDATE(&wasm_module),
            (x/canvas_scale_x) - canvas_x_offset,
            (y/canvas_scale_y) - canvas_y_offset);
}

static void resize(GLFWwindow* window, int width, int height) {
    glfwGetMonitorContentScale(
            glfwGetPrimaryMonitor(),
            &canvas_scale_x, &canvas_scale_y);

    float fwidth = ((float) width) / canvas_scale_x;
    float fheight = ((float) height) / canvas_scale_y;

    if (fwidth > (float) MAX_CANVAS_WIDTH) {
        canvas_x_offset = ((int) fwidth - MAX_CANVAS_WIDTH) / 2;
        canvas_width = MAX_CANVAS_WIDTH;
    } else {
        canvas_x_offset = 0;
        canvas_width = (int) fwidth;
    }

    if (fheight > (float) MAX_CANVAS_HEIGHT) {
        canvas_y_offset = ((int) fheight - MAX_CANVAS_HEIGHT) / 2;
        canvas_height = MAX_CANVAS_HEIGHT;
    } else {
        canvas_y_offset = 0;
        canvas_height = (int) fheight;
    }

    w2c_snake_resize(&wasm_module, canvas_width, canvas_height);
    w2c_snake_update(&wasm_module, glfwGetTime()*1000);
}

int main(void) {
    // Initialize WASM runtime and module
    wasm_rt_init();
    wasm2c_snake_instantiate(&wasm_module, &wasm_imports);

    // Initialize GLFW window
    glfwSetErrorCallback(glfw_error_callback);
    if (!glfwInit()) {
        return -1;
    }
    GLFWwindow* window = glfwCreateWindow(
            MAX_CANVAS_WIDTH, MAX_CANVAS_HEIGHT,
            "WAT the Snake",
            NULL, NULL);
    if (!window) {
        glfwTerminate();
        return EXIT_FAILURE;
    }
    glfwMakeContextCurrent(window);
    glfwSetKeyCallback(window, handle_key_action);
    glfwSetMouseButtonCallback(window, handle_mouse_button);
    glfwSetCursorPosCallback(window, handle_cursor_position);
    glfwSetWindowSizeCallback(window, resize);

    // Game loop
    glfwSwapInterval(1);
    glClearColor(3.0/16, 1.0/16, 3.0/16, 1.0);
    size_t canvas_memory_offset =
        (size_t) *w2c_snake_memoryRegionCanvasBytesOffset(&wasm_module);
    while (!glfwWindowShouldClose(window)) {
        w2c_snake_update(&wasm_module, glfwGetTime()*1000);

        glClear(GL_COLOR_BUFFER_BIT);
        glViewport(
                canvas_x_offset*canvas_scale_x, canvas_y_offset*canvas_scale_y,
                canvas_width*canvas_scale_x, canvas_height*canvas_scale_y);
        glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
        glRasterPos2f(-1.0, -1.0);
        glPixelZoom(canvas_scale_x, canvas_scale_y);
        uint8_t* canvas_rgba_data_ptr =
            &w2c_snake_memory(&wasm_module)->data[canvas_memory_offset];
        glDrawPixels(
                canvas_width, canvas_height,
                GL_RGBA, GL_UNSIGNED_BYTE,
                canvas_rgba_data_ptr);

        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    // Destroy window and exit
    glfwTerminate();
    // NOTE: We DON'T free the WASM stuff because the OS will
    //       do that for us when the process exits.
    //       It'd be a waste of resources.
    return EXIT_SUCCESS;
}

void w2c_imports_logFromNBytesOfMemory(
        w2c_imports* imports, u32 n_bytes
) {
    size_t memory_offset =
        (size_t) *w2c_snake_memoryRegionLogBytesOffset(&wasm_module);
    for (size_t i = 0; i < n_bytes; ++i) {
        putchar(w2c_snake_memory(&wasm_module)->data[memory_offset + i]);
    }
    putchar('\n');
}

