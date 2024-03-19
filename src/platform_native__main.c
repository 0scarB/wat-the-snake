#include <stdint.h>
#include <stdio.h>
#include <stdio.h>
#include <GLFW/glfw3.h>
#include "snake.h"

typedef struct w2c_imports {
    wasm_rt_memory_t memory;
    u32 canvas_width;
    u32 canvas_height;
} w2c_imports;

wasm_rt_memory_t* w2c_snake_mem(w2c_imports* instance) {
  return &instance->memory;
}

u32* w2c_imports_canvasHeight(w2c_imports* imports) {
    return &imports->canvas_width;
}
u32* w2c_imports_canvasWidth(w2c_imports* imports) {
    return &imports->canvas_width;
}

w2c_snake snake;

void w2c_imports_logFromNBytesOfMemory(w2c_imports* imports, u32 n_bytes) {
    for (size_t i = 0; i < n_bytes; ++i) {
        putchar(w2c_snake_memory(&snake)->data[i]);
    }
    putchar('\n');
}

int main(void) {
    /* Initialize the Wasm runtime. */
    wasm_rt_init();

    w2c_imports imports;
    imports.canvas_width = 640;
    imports.canvas_height = 640;
    /* Construct the module instance. */
    wasm2c_snake_instantiate(&snake, &imports);

    w2c_snake_update(&snake, 0.0);

    GLFWwindow* window;

    if (!glfwInit()) {
        return -1;
    }

    window = glfwCreateWindow(640, 640, "WAT the Snake", NULL, NULL);
    if (!window) {
        glfwTerminate();
        return -1;
    }

    glfwMakeContextCurrent(window);

    while (!glfwWindowShouldClose(window)) {
        glClear(GL_COLOR_BUFFER_BIT);
        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    glfwTerminate();
    return 0;
}
