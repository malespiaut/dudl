const std = @import("std");
const c = @cImport({
    @cInclude("SDL3/SDL.h");
});

const log = std.debug.print;

const Color = enum {
    Red,
    Blue,
    Green,
    Yellow,
    White,
    Black,
};

pub fn colorToNumber(color: Color) u8 {
    return switch (color) {
        Color.Red => 1,
        Color.Blue => 2,
        Color.Green => 3,
        Color.Yellow => 4,
        Color.White => 5,
        Color.Black => 6,
    };
}

pub fn numberToColor(number: u8) Color {
    return switch (number) {
        1 => Color.Red,
        2 => Color.Blue,
        3 => Color.Green,
        4 => Color.Yellow,
        5 => Color.White,
        6 => Color.Black,
        else => unreachable,
    };
}

pub fn sdlSetDrawColor(color: Color, renderer: ?*c.SDL_Renderer) void {
    return switch (color) {
        Color.Red => {
            _ = c.SDL_SetRenderDrawColor(renderer, 255, 0, 0, 255);
        },
        Color.Blue => {
            _ = c.SDL_SetRenderDrawColor(renderer, 131, 182, 209, 255);
        },
        Color.Green => {
            _ = c.SDL_SetRenderDrawColor(renderer, 64, 216, 92, 255);
        },
        Color.Yellow => {
            _ = c.SDL_SetRenderDrawColor(renderer, 255, 255, 0, 255);
        },
        Color.White => {
            _ = c.SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
        },
        Color.Black => {
            _ = c.SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        },
    };
}

pub fn sdlClearBackground(renderer: ?*c.SDL_Renderer) void {
    _ = c.SDL_SetRenderDrawColor(renderer, 66, 66, 66, 255);
    _ = c.SDL_RenderClear(renderer);
}

pub fn clamp(comptime T: type, value: T, min: T, max: T) T {
    if (value < min) {
        return min;
    } else if (value > max) {
        return max;
    } else {
        return value;
    }
}

pub fn main() !void {
    log("dudl!\n", .{});

    // config
    const window_width = 640;
    const window_height = 480;

    // state
    var quit = false;
    var should_draw = false;
    var brush_size: i32 = 10;
    var color: Color = Color.White;

    // make u8 buffer with a pixel for each pixel in the window
    var buffer = try std.heap.c_allocator.alloc(u8, window_width * window_height * 4);
    defer std.heap.c_allocator.free(buffer);

    // fill buffer with 0
    for (buffer) |*pixel| {
        pixel.* = 0;
    }

    _ = c.SDL_Init(c.SDL_INIT_VIDEO);
    defer c.SDL_Quit();

    const sdl_window = c.SDL_CreateWindow("Hello World", window_width, window_height, 0) orelse {
        log("sdl create window failed {s}\n", .{c.SDL_GetError()});
        return error.SDLWindowCreationFailed;
    };
    defer c.SDL_DestroyWindow(sdl_window);

    const sdl_renderer = c.SDL_CreateRenderer(sdl_window, null) orelse {
        log("sdl create renderer failed {s}\n", .{c.SDL_GetError()});
        return error.SDLRendererCreationFailed;
    };
    defer c.SDL_DestroyRenderer(sdl_renderer);

    sdlClearBackground(sdl_renderer);
    _ = c.SDL_RenderPresent(sdl_renderer) or {
        log("sdl render present failed {s}\n", .{c.SDL_GetError()});
        return error.SDLRenderPresentFailed;
    };

    while (!quit) {
        sdlClearBackground(sdl_renderer);
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event)) {
            switch (event.type) {
                c.SDL_EVENT_QUIT => {
                    quit = true;
                },
                c.SDL_EVENT_KEY_DOWN => {
                    const keydown_key = event.key.key;
                    switch (keydown_key) {
                        c.SDLK_Q => {
                            log("bye bye\n", .{});
                            quit = true;
                        },
                        c.SDLK_T => {
                            brush_size += 1;
                            log("bush+ to {d}\n", .{brush_size});
                        },
                        c.SDLK_H => {
                            brush_size -= 1;
                            log("bush- to {d}\n", .{brush_size});
                        },
                        c.SDLK_B => {
                            color = Color.Blue;
                            log("blue\n", .{});
                        },
                        c.SDLK_G => {
                            color = Color.Green;
                            log("green\n", .{});
                        },
                        c.SDLK_W => {
                            color = Color.White;
                            log("white\n", .{});
                        },
                        c.SDLK_R => {
                            color = Color.Red;
                            log("red\n", .{});
                        },
                        c.SDLK_Y => {
                            color = Color.Yellow;
                            log("yellow\n", .{});
                        },
                        c.SDLK_X => {
                            color = Color.Black;
                            log("black\n", .{});
                        },
                        c.SDLK_ESCAPE => {
                            log("clearing buffer\n", .{});
                            for (buffer) |*pixel| {
                                pixel.* = 0;
                            }
                        },
                        else => {
                            log("key {d} has no use\n", .{keydown_key});
                        },
                    }
                },
                // mose button down
                c.SDL_EVENT_MOUSE_BUTTON_DOWN => {
                    should_draw = true;
                },
                c.SDL_EVENT_MOUSE_BUTTON_UP => {
                    should_draw = false;
                },
                else => {},
            }
        }

        // fetch mouse hover position
        var mouse_x: f32 = undefined;
        var mouse_y: f32 = undefined;
        if (should_draw) {
            _ = c.SDL_GetMouseState(&mouse_x, &mouse_y);
            // set the buffer value at the mouse position to 1

            const location: i32 = clamp(i32, @as(i32, @intFromFloat(mouse_x)) + @as(i32, @intFromFloat(mouse_y)) * window_width, 0, @as(i32, @intCast(buffer.len)));
            const position: usize = @intCast(location);
            buffer[position] = colorToNumber(color);
        }

        // draw a white pixel on the screen for each value in buffer that is not 0
        for (buffer, 0..) |*pixel, i| {
            if (pixel.* != 0) {
                const x: i32 = @intCast(i % window_width);
                const y: i32 = @intCast(i / window_width);
                // _ = c.SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
                // _ = c.SDL_RenderDrawPoint(renderer, x, y);

                // get a random number between 0 and 255
                // const rx: i32 = @mod(std.crypto.random.int(i32), 100) - 5;
                // const ry: i32 = @mod(std.crypto.random.int(i32), 100) - 5;
                // _ = ry;
                const rx: i32 = 0;
                // const ry: i32 = 0;

                // std.debug.print("r: {d}", .{r});

                // for loop 100 times
                // var index: u8 = 0;
                // _ = index;
                // while (index < 250) : (index += 1) {
                // set the pixel at x + i to r
                const pixel_color = numberToColor(pixel.*);
                sdlSetDrawColor(pixel_color, sdl_renderer);
                // fill rect
                _ = c.SDL_RenderFillRect(sdl_renderer, &c.SDL_FRect{
                    .x = @floatFromInt(@mod(x + rx, window_width)),
                    .y = @floatFromInt(@mod(y + rx, window_height)),
                    // .x = clamp(i32, x + rx, 0, window_width),
                    // .y = clamp(i32, y + rx, 0, window_height),
                    .w = @floatFromInt(brush_size),
                    .h = @floatFromInt(brush_size),
                });
                // }
                // sleep for 100ms second
            }
        }

        // std.time.sleep(std.time.ns_per_s / 10);
    _ = c.SDL_RenderPresent(sdl_renderer) or {
        log("sdl render present failed {s}\n", .{c.SDL_GetError()});
        return error.SDLRenderPresentFailed;
    };
    }
}
