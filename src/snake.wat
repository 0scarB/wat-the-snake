(module
    ;; Imports
    ;; ----------------------------------------------------------------------

    (global $canvas_width     (import "imports" "canvasWidth" ) i32)
    (global $canvas_height    (import "imports" "canvasHeight") i32)

    (func $extern_log
        (import "imports" "logFromNBytesOfMemory") (param i32))
    (func $extern_get_unix_timestamp
        (import "imports" "getUnixTimestamp") (param) (result i32))


    ;; Memory
    ;; ----------------------------------------------------------------------

    (memory $memory 4096 4096)
    (export "memory" (memory $memory))
    (global $memory_region_log_bytes_n          i32          (i32.const 1024))
    (global $memory_region_snake_circles_xs_bytes_offset i32 (i32.const 1024))
    (global $memory_region_snake_circles_xs_bytes_n i32      (i32.const 4096))
    (global $memory_region_snake_circles_ys_bytes_offset i32 (i32.const 5120))
    (global $memory_region_snake_circles_ys_bytes_n i32      (i32.const 4096))
    (global $memory_region_canvas_bytes_offset  i32          (i32.const 65536))
    (global $memory_region_canvas_bytes_n  (mut i32)         (i32.const 1024))
    (export "memoryRegionLogBytesN"         (global $memory_region_log_bytes_n        ))
    (export "memoryRegionCanvasBytesOffset" (global $memory_region_canvas_bytes_offset))
    (export "memoryRegionCanvasBytesN"      (global $memory_region_canvas_bytes_n     ))


    ;; Gloabl Constants
    ;; ----------------------------------------------------------------------

    (global $TARGET_FRAMERATE i32 (i32.const 30))
    (global $SNAKE_MOVEMENT_PX_PER_S i32 (i32.const 100))
    (global $SNAKE_WIDTH i32 (i32.const 50))

    ;; Character code constants
    (global $CHAR_SPACE i32 (i32.const 32))
    (global $CHAR_0 i32 (i32.const 48))
    (global $CHAR_1 i32 (i32.const 49))
    (global $CHAR_2 i32 (i32.const 50))
    (global $CHAR_3 i32 (i32.const 51))
    (global $CHAR_4 i32 (i32.const 52))
    (global $CHAR_5 i32 (i32.const 53))
    (global $CHAR_6 i32 (i32.const 54))
    (global $CHAR_7 i32 (i32.const 55))
    (global $CHAR_8 i32 (i32.const 56))
    (global $CHAR_9 i32 (i32.const 57))
    (global $CHAR_COLON i32 (i32.const 58))
    (global $CHAR_a i32 (i32.const 97))
    (global $CHAR_b i32 (i32.const 98))
    (global $CHAR_c i32 (i32.const 99))
    (global $CHAR_d i32 (i32.const 100))
    (global $CHAR_e i32 (i32.const 101))
    (global $CHAR_f i32 (i32.const 102))
    (global $CHAR_g i32 (i32.const 103))
    (global $CHAR_h i32 (i32.const 104))
    (global $CHAR_i i32 (i32.const 105))
    (global $CHAR_j i32 (i32.const 106))
    (global $CHAR_k i32 (i32.const 107))
    (global $CHAR_l i32 (i32.const 108))
    (global $CHAR_m i32 (i32.const 109))
    (global $CHAR_n i32 (i32.const 110))
    (global $CHAR_o i32 (i32.const 111))
    (global $CHAR_p i32 (i32.const 112))
    (global $CHAR_q i32 (i32.const 113))
    (global $CHAR_r i32 (i32.const 114))
    (global $CHAR_s i32 (i32.const 115))
    (global $CHAR_t i32 (i32.const 116))
    (global $CHAR_u i32 (i32.const 117))
    (global $CHAR_v i32 (i32.const 118))
    (global $CHAR_w i32 (i32.const 119))
    (global $CHAR_x i32 (i32.const 120))
    (global $CHAR_y i32 (i32.const 121))
    (global $CHAR_z i32 (i32.const 122))

    ;; Logger Implementation
    ;; ----------------------------------------------------------------------

    (global $log_msg_len (mut i32) (i32.const 0))

    ;; Store a latin1 character code as a byte at the next position
    ;; in the logging memory.
    (func $log_char (param $char_code i32)
        (i32.store (global.get $log_msg_len) (local.get $char_code))

        (i32.add (global.get $log_msg_len) (i32.const 1))
        global.set $log_msg_len
    )

    ;; Store the latin1 character codes of the digits in an i32 integer
    ;; at the next positions in the logging memory.
    (func $log_i32 (param $x i32)
        (local $factor_10 i32)
        (local $most_significant_digit i32)

        ;; Set factor_10 to 10^places where places is the number of
        ;; digits (in base 10) in x
        (local.set $factor_10 (i32.const 1))

        (loop $lp
            ;; factor_10 *= 10
            (local.set $factor_10 (i32.mul (local.get $factor_10) (i32.const 10)))

            ;; loop while x/factor_10 > 9
            (i32.gt_s
                (i32.div_s (local.get $x) (local.get $factor_10))
                (i32.const 9))
            br_if $lp
        )

        ;; Store the characters of the digits from x (in base 10) in
        ;; the logging memory in order from the most significant digit to
        ;; the least
        (loop $lp
            ;; Calculate the most siginifcant digit (in base 10):
            ;;      most_significant_digit = x/factor_10
            (local.set $most_significant_digit 
                (i32.div_s (local.get $x) (local.get $factor_10)))

            ;; Store the latin1 character code of the most significant digit 
            ;; in the logging memeory:
            ;;      log_char(most_significant_digit + CHAR_0)
            (call $log_char 
                (i32.add (local.get $most_significant_digit) (global.get $CHAR_0)))

            ;; Remove the most significant digit (in base 10) from x:
            ;;      x -= most_significant_digit*factor_10
            (local.set $x (i32.sub
                (local.get $x)
                (i32.mul (local.get $most_significant_digit) (local.get $factor_10))))

            ;; factor_10 /= 10
            (local.set $factor_10 (i32.div_s (local.get $factor_10) (i32.const 10)))

            ;; loop while factor_10 > 0
            (i32.gt_s (local.get $factor_10) (i32.const 0))
            br_if $lp
        )
    )

    ;; 1. Call the external function $log_extern(<number of bytes in log message>),
    ;;    triggering the external logger to log based on the bytes stored in the
    ;;    logging memory region.
    ;; 2. Reset the index of the byte of the next log character
    (func $log_flush (param)
        global.get $log_msg_len
        call $extern_log

        i32.const 0
        global.set $log_msg_len
    )


    ;; Canvas Implementation
    ;; ----------------------------------------------------------------------

    (func $calc_memory_region_canvas_bytes_n (result i32)
        (i32.mul
            (i32.mul (global.get $canvas_width) (global.get $canvas_height))
            (i32.const 4))
    )

    (func $fill_rect
            (param $x       i32) (param $y      i32)
            (param $width   i32) (param $height i32)
            (param $r i32) (param $g i32) (param $b i32) (param $a i32)
        (local $byte_address i32)
        ;; Set rect bounds
        (local $min_x i32)
        (local $min_y i32)
        (local $max_x i32)
        (local $max_y i32)
        (local.set $min_x (local.get $x))
        (local.set $min_y (local.get $y))
        (local.set $max_x (i32.add (local.get $x) (local.get $width)))
        (local.set $max_y (i32.add (local.get $y) (local.get $height)))

        ;; Return if rect is outside of canvas
        (i32.lt_s (local.get $max_x) (i32.const 0))
        (if (then return))
        (i32.lt_s (local.get $max_y) (i32.const 0))
        (if (then return))
        (i32.ge_s (local.get $min_x) (global.get $canvas_width))
        (if (then return))
        (i32.ge_s (local.get $min_y) (global.get $canvas_height))
        (if (then return))

        ;; Clamp rect bounds inside of canvas
        (i32.lt_s (local.get $min_x) (i32.const 0))
        (if (then
            (local.set $min_x (i32.const 0))
        ))
        (i32.lt_s (local.get $min_y) (i32.const 0))
        (if (then
            (local.set $min_y (i32.const 0))
        ))
        (i32.ge_s (local.get $max_x) (global.get $canvas_width))
        (if (then
            (local.set $max_x (i32.sub (global.get $canvas_width) (i32.const 1)))
        ))
        (i32.ge_s (local.get $max_y) (global.get $canvas_height))
        (if (then
            (local.set $max_y (i32.sub (global.get $canvas_height) (i32.const 1)))
        ))

        (local.set $x (local.get $min_x))
        (block $while_lt_max_x (loop $x_lp
            ;; while condition
            (i32.eq (local.get $x) (local.get $max_x))
            br_if $while_lt_max_x

            (local.set $y (local.get $min_y))
            (block $while_lt_max_y (loop $y_lp
                ;; while condition
                (i32.eq (local.get $y) (local.get $max_y))
                br_if $while_lt_max_y

                (local.set $byte_address 
                    (i32.add
                        (i32.mul
                            (i32.add
                                (i32.mul (local.get $y) (global.get $canvas_width))
                                (local.get $x))
                            (i32.const 4))
                        (global.get $memory_region_canvas_bytes_offset)))

                (i32.store (local.get $byte_address) (local.get $r))
                (local.set $byte_address (i32.add (local.get $byte_address) (i32.const 1)))
                (i32.store (local.get $byte_address) (local.get $g))
                (local.set $byte_address (i32.add (local.get $byte_address) (i32.const 1)))
                (i32.store (local.get $byte_address) (local.get $b))
                (local.set $byte_address (i32.add (local.get $byte_address) (i32.const 1)))
                (i32.store (local.get $byte_address) (local.get $a))

                (local.set $y (i32.add (local.get $y) (i32.const 1)))
                br $y_lp
            ))

            (local.set $x (i32.add (local.get $x) (i32.const 1)))
            br $x_lp
        ))
    )

    (func $fill_circle
            (param $cx i32) (param $cy i32) (param $radius i32)
            (param $r i32) (param $g i32) (param $b i32) (param $a i32)
        (local $byte_address i32)
        (local $x i32)
        (local $y i32)
        (local $dx i32)
        (local $dy i32)
        ;; Set rect bounds
        (local $min_x i32)
        (local $min_y i32)
        (local $max_x i32)
        (local $max_y i32)
        (local.set $min_x (i32.sub (local.get $cx) (local.get $radius)))
        (local.set $min_y (i32.sub (local.get $cy) (local.get $radius)))
        (local.set $max_x (i32.add (local.get $cx) (local.get $radius)))
        (local.set $max_y (i32.add (local.get $cy) (local.get $radius)))

        ;; Return if rect is outside of canvas
        (i32.lt_s (local.get $max_x) (i32.const 0))
        (if (then return))
        (i32.lt_s (local.get $max_y) (i32.const 0))
        (if (then return))
        (i32.ge_s (local.get $min_x) (global.get $canvas_width))
        (if (then return))
        (i32.ge_s (local.get $min_y) (global.get $canvas_height))
        (if (then return))

        ;; Clamp rect bounds inside of canvas
        (i32.lt_s (local.get $min_x) (i32.const 0))
        (if (then
            (local.set $min_x (i32.const 0))
        ))
        (i32.lt_s (local.get $min_y) (i32.const 0))
        (if (then
            (local.set $min_y (i32.const 0))
        ))
        (i32.ge_s (local.get $max_x) (global.get $canvas_width))
        (if (then
            (local.set $max_x (i32.sub (global.get $canvas_width) (i32.const 1)))
        ))
        (i32.ge_s (local.get $max_y) (global.get $canvas_height))
        (if (then
            (local.set $max_y (i32.sub (global.get $canvas_height) (i32.const 1)))
        ))

        (local.set $x (local.get $min_x))
        (block $while_lt_max_x (loop $x_lp
            ;; while condition
            (i32.eq (local.get $x) (local.get $max_x))
            br_if $while_lt_max_x

            (local.set $y (local.get $min_y))
            (block $while_lt_max_y (loop $y_lp
                ;; while condition
                (i32.eq (local.get $y) (local.get $max_y))
                br_if $while_lt_max_y

                ;; Only fill pixel if [(x - cx)^2 + (y - cy)^2] <= radius^2
                (local.set $dx (i32.sub (local.get $x) (local.get $cx)))
                (local.set $dy (i32.sub (local.get $y) (local.get $cy)))
                (i32.le_s
                    (i32.add
                        (i32.mul (local.get $dx) (local.get $dx))
                        (i32.mul (local.get $dy) (local.get $dy))
                    )
                    (i32.mul (local.get $radius) (local.get $radius))
                )
                (if (then
                    (local.set $byte_address 
                        (i32.add
                            (i32.mul
                                (i32.add
                                    (i32.mul (local.get $y) (global.get $canvas_width))
                                    (local.get $x))
                                (i32.const 4))
                            (global.get $memory_region_canvas_bytes_offset)))

                    (i32.store (local.get $byte_address) (local.get $r))
                    (local.set $byte_address
                        (i32.add (local.get $byte_address) (i32.const 1)))
                    (i32.store (local.get $byte_address) (local.get $g))
                    (local.set $byte_address
                        (i32.add (local.get $byte_address) (i32.const 1)))
                    (i32.store (local.get $byte_address) (local.get $b))
                    (local.set $byte_address
                        (i32.add (local.get $byte_address) (i32.const 1)))
                    (i32.store (local.get $byte_address) (local.get $a))
                ))

                (local.set $y (i32.add (local.get $y) (i32.const 1)))
                br $y_lp
            ))

            (local.set $x (i32.add (local.get $x) (i32.const 1)))
            br $x_lp
        ))
    )

    ;; Fill the whole canvas with the color from the RGBA channel values
    (func $fill_canvas (param $r i32) (param $g i32) (param $b i32) (param $a i32)
        (local $i i32)
        (local $channel_idx i32)
        (local $byte_address i32)

        ;; i = 0
        (local.set $i (i32.const 0))

        (loop $lp
            ;; Set the byte value of the relevant channel
            (local.set $channel_idx (i32.rem_u (local.get $i) (i32.const 4)))
            (local.set $byte_address 
                (i32.add (global.get $memory_region_canvas_bytes_offset) (local.get $i)))
            (block $if_else
                (i32.eq (local.get $channel_idx) (i32.const 0))
                (if (then
                    (i32.store (local.get $byte_address) (local.get $r))
                    br $if_else
                ))
                (i32.eq (local.get $channel_idx) (i32.const 1))
                (if (then
                    (i32.store (local.get $byte_address) (local.get $g))
                    br $if_else
                ))
                (i32.eq (local.get $channel_idx) (i32.const 2))
                (if (then
                    (i32.store (local.get $byte_address) (local.get $b))
                    br $if_else
                ))
                (i32.eq (local.get $channel_idx) (i32.const 3))
                (if (then
                    (i32.store (local.get $byte_address) (local.get $a))
                    br $if_else
                ))
            )

            ;; i += 1
            (local.set $i (i32.add (local.get $i) (i32.const 1)))

            ;; loop while i != memory_region_canvas_bytes_n
            (i32.ne (local.get $i) (global.get $memory_region_canvas_bytes_n))
            br_if $lp
        )
    )


    ;; Game Logic
    ;; ----------------------------------------------------------------------

    (global $game_is_initialized        (mut i32) (i32.const  0))
    (global $frame_timestamp            (mut i32) (i32.const -1))
    (global $snake_circle_tail_x_ptr    (mut i32) (i32.const -1))
    (global $snake_circle_tail_y_ptr    (mut i32) (i32.const -1))
    (global $snake_circle_head_x_ptr    (mut i32) (i32.const -1))
    (global $snake_circle_head_y_ptr    (mut i32) (i32.const -1))
    (global $snake_direction_x          (mut i32) (i32.const  1))
    (global $snake_direction_y          (mut i32) (i32.const  0))
    (global $snake_length               (mut i32) (i32.const  0))
    (global $snake_target_length        (mut i32) (i32.const -1))

    (func $dist
            (param $x1 i32) (param $y1 i32)
            (param $x2 i32) (param $y2 i32)
            (result i32)
        ;; TODO Use sqrt distance instead of Manhattan
        (local $x_dist i32)
        (local $y_dist i32)

        (local.set $x_dist (i32.sub (local.get $x2) (local.get $x1)))
        (i32.lt_s (local.get $x_dist) (i32.const 0))
        (if (then
            (local.set $x_dist (i32.sub (i32.const 0) (local.get $x_dist)))
        ))

        (local.set $y_dist (i32.sub (local.get $y2) (local.get $y1)))
        (i32.lt_s (local.get $y_dist) (i32.const 0))
        (if (then
            (local.set $y_dist (i32.sub (i32.const 0) (local.get $y_dist)))
        ))

        (i32.add (local.get $x_dist) (local.get $y_dist))
    )

    (func $snake_move
        (local $snake_head_delta_pos i32)
        (local $x i32)
        (local $y i32)
        (local $dist_to_last_head i32)

        (local.set $snake_head_delta_pos
            (i32.div_s
                (global.get $SNAKE_MOVEMENT_PX_PER_S)
                (global.get $TARGET_FRAMERATE)))

        (local.set $x
            (i32.add
                (i32.load16_u 
                    (i32.sub 
                        (global.get $snake_circle_head_x_ptr)
                        (i32.const 2)))
                (i32.mul (global.get $snake_direction_x) (local.get $snake_head_delta_pos))))
        (local.set $y
            (i32.add
                (i32.load16_u 
                    (i32.sub 
                        (global.get $snake_circle_head_y_ptr)
                        (i32.const 2)))
                (i32.mul (global.get $snake_direction_y) (local.get $snake_head_delta_pos))))

        ;; Calculate distance to last head circle
        (i32.eq
            (global.get $snake_circle_tail_x_ptr)
            (global.get $snake_circle_head_x_ptr))
        if 
            (local.set $dist_to_last_head (i32.const 0))
        else
            (local.set $dist_to_last_head
                (call $dist
                    (i32.load16_u
                        (i32.sub 
                            (global.get $snake_circle_head_x_ptr)
                            (i32.const 2)))
                    (i32.load16_u
                        (i32.sub
                            (global.get $snake_circle_head_y_ptr)
                            (i32.const 2)))
                    (local.get $x)
                    (local.get $y)))
        end

        ;; Store x value and increment x pointer
        (i32.store16
            (global.get $snake_circle_head_x_ptr)
            ( local.get $x))
        (global.set $snake_circle_head_x_ptr
            (i32.add (global.get $snake_circle_head_x_ptr) (i32.const 2)))

        ;; Store y value and increment y pointer
        (i32.store16
            (global.get $snake_circle_head_y_ptr)
            ( local.get $y))
        (global.set $snake_circle_head_y_ptr
            (i32.add (global.get $snake_circle_head_y_ptr) (i32.const 2)))

        (global.set $snake_length
            (i32.add (global.get $snake_length) (local.get $dist_to_last_head)))
        ;; Drop tail if length is greater than target length
        (i32.gt_u (global.get $snake_length) (global.get $snake_target_length))
        (if (then
            (global.set $snake_circle_tail_x_ptr
                (i32.add (global.get $snake_circle_tail_x_ptr) (i32.const 2)))
            (global.set $snake_circle_tail_y_ptr
                (i32.add (global.get $snake_circle_tail_y_ptr) (i32.const 2)))
        ))
    )

    (func $snake_draw
        (local $circle_x_ptr i32)
        (local $circle_y_ptr i32)

        (local.set $circle_x_ptr (global.get $snake_circle_tail_x_ptr))
        (local.set $circle_y_ptr (global.get $snake_circle_tail_y_ptr))

        (block $while (loop $lp
            (i32.ge_s
                (local.get $circle_x_ptr)
                (i32.sub (global.get $snake_circle_head_x_ptr) (i32.const 2)))
            br_if $while

            (call $fill_circle
                (i32.load16_u (local.get $circle_x_ptr))
                (i32.load16_u (local.get $circle_y_ptr))
                (i32.div_s (global.get $SNAKE_WIDTH) (i32.const 2))
                (i32.const 0) (i32.const 255) (i32.const 0) (i32.const 255))

            (local.set $circle_x_ptr (i32.add (local.get $circle_x_ptr) (i32.const 2)))
            (local.set $circle_y_ptr (i32.add (local.get $circle_y_ptr) (i32.const 2)))

            br $lp
        ))
    )

    (func (export "update")
        (local $snake_head_delta_pos i32)
        (local $snake_circle_x_ptr i32)
        (local $snake_circle_y_ptr i32)
        (local $snake_circle_x i32)
        (local $snake_circle_y i32)

        (i32.eq (global.get $game_is_initialized) (i32.const 0))
        (if (then
            (global.set $snake_circle_tail_x_ptr
                (global.get $memory_region_snake_circles_xs_bytes_offset))
            (global.set $snake_circle_tail_y_ptr
                (global.get $memory_region_snake_circles_ys_bytes_offset))
            (global.set $snake_circle_head_x_ptr
                (global.get $memory_region_snake_circles_xs_bytes_offset))
            (global.set $snake_circle_head_y_ptr
                (global.get $memory_region_snake_circles_ys_bytes_offset))
            (global.set $frame_timestamp (call $extern_get_unix_timestamp))
            (global.set $snake_target_length (i32.const 1000))
            (global.set $game_is_initialized (i32.const 1))
        ))

        ;; Calculated and set memory region size of RGBA canvas bytes
        (global.set $memory_region_canvas_bytes_n 
            (call $calc_memory_region_canvas_bytes_n))

        (call $snake_move)

        (call $fill_canvas (i32.const 0) (i32.const 0) (i32.const 0) (i32.const 255))

        call $snake_draw
    )

    (func (export "shouldUpdate") (result i32)
        (local $millis_between_frames i32)

        (i32.eq (global.get $game_is_initialized) (i32.const 0))
        (if (then
            i32.const 1
            return
        ))

        (local.set $millis_between_frames 
            (i32.div_u (i32.const 1000) (global.get $TARGET_FRAMERATE)))

        (i32.lt_s
            (call $extern_get_unix_timestamp) (global.get $frame_timestamp))
        (if (then 
            i32.const 0
            return
        ))

        (global.set $frame_timestamp
            (i32.add 
                (global.get $frame_timestamp)
                (local.get $millis_between_frames)))

        i32.const 1
        return
    )

    (func (export "handleKeyDown") (param $key i32)
        (block $switch
            (i32.eq (local.get $key) (global.get $CHAR_w))
            (if (then
                (global.set $snake_direction_x (i32.const  0))
                (global.set $snake_direction_y (i32.const -1))
                br $switch
            ))
            (i32.eq (local.get $key) (global.get $CHAR_s))
            (if (then
                (global.set $snake_direction_x (i32.const  0))
                (global.set $snake_direction_y (i32.const  1))
                br $switch
            ))
            (i32.eq (local.get $key) (global.get $CHAR_a))
            (if (then
                (global.set $snake_direction_x (i32.const -1))
                (global.set $snake_direction_y (i32.const  0))
                br $switch
            ))
            (i32.eq (local.get $key) (global.get $CHAR_d))
            (if (then
                (global.set $snake_direction_x (i32.const  1))
                (global.set $snake_direction_y (i32.const  0))
                br $switch
            ))
        )
    )
)

