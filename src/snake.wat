(module
    ;; Imports
    ;; ----------------------------------------------------------------------

    (func $extern_log (import "imports" "logFromNBytesOfMemory") (param i32))


    ;; Memory
    ;; ----------------------------------------------------------------------

    (memory $memory (export "memory") 1 64)
    (global $memory_region_log_bytes_offset              i32  (i32.const 0))
    (global $memory_region_log_bytes_n                   i32  (i32.const 2048))
    (global $memory_region_snake_buf_offset              i32  (i32.const 2048))
    (global $memory_region_snake_buf_bytes_n             i32  (i32.const 63488))
    (global $memory_region_canvas_bytes_offset           i32  (i32.const 65536))
    (global $memory_region_canvas_bytes_n           (mut i32) (i32.const 0))
    (global $memory_current_pages_n                 (mut i32) (i32.const 1))
    (export "memoryRegionLogBytesOffset"    (global $memory_region_log_bytes_offset   ))
    (export "memoryRegionLogBytesN"         (global $memory_region_log_bytes_n        ))
    (export "memoryRegionCanvasBytesOffset" (global $memory_region_canvas_bytes_offset))
    (export "memoryRegionCanvasBytesN"      (global $memory_region_canvas_bytes_n     ))


    ;; Game Logic
    ;; ----------------------------------------------------------------------

    (global $INPUT_START  (export "INPUT_START" ) i32 (i32.const 0))
    (global $INPUT_UPDATE (export "INPUT_UPDATE") i32 (i32.const 1))
    (global $INPUT_END    (export "INPUT_END"   ) i32 (i32.const 2))

    ;; We export the character codes (integers) that can be used as inputs to
    ;; change the snake's heading (direction). Letter keys are assigned to their
    ;; ASCII character codes, making it easier to implement platform specific
    ;; bindings based on keyboard input.
    ;; Arrow keys are given codes that lie in the Latin1 0x80-0x9F control codes,
    ;; as they are unlikely to occur during keyboard input. Additionally,
    ;; determining the heading is arithmetically easy because the correspoding
    ;; groups containing a lower case letter, uppercase letter and arrow key
    ;; share the same lower 5-bits.
    (global $KEY_SPACE   (export "KEY_SPACE"  ) i32 (i32.const   32))
    (global $KEY_W       (export "KEY_W"      ) i32 (i32.const 0x57)) ;;---+ 0b xxx1 0111
    (global $KEY_w       (export "KEY_w"      ) i32 (i32.const 0x77)) ;;--/
    (global $ARROW_UP    (export "ARROW_UP"   ) i32 (i32.const 0x97)) ;;-/
    (global $KEY_A       (export "KEY_A"      ) i32 (i32.const 0x41)) ;;---+ 0b xxx0 0001
    (global $KEY_a       (export "KEY_a"      ) i32 (i32.const 0x61)) ;;--/
    (global $ARROW_LEFT  (export "ARROW_LEFT" ) i32 (i32.const 0x81)) ;;-/
    (global $KEY_S       (export "KEY_S"      ) i32 (i32.const 0x53)) ;;---+ 0b xxx1 0011
    (global $KEY_s       (export "KEY_s"      ) i32 (i32.const 0x73)) ;;--/
    (global $ARROW_DOWN  (export "ARROW_DOWN" ) i32 (i32.const 0x93)) ;;-/
    (global $KEY_D       (export "KEY_D"      ) i32 (i32.const 0x44)) ;;---+ 0b xxx0 0100
    (global $KEY_d       (export "KEY_d"      ) i32 (i32.const 0x64)) ;;--/
    (global $ARROW_RIGHT (export "ARROW_RIGHT") i32 (i32.const 0x84)) ;;-/

    (global $KEY_IS_DOWN_RIGHT  i32 (i32.const 1))
    (global $KEY_IS_DOWN_LEFT   i32 (i32.const 2))
    (global $KEY_IS_DOWN_UP     i32 (i32.const 4))
    (global $KEY_IS_DOWN_DOWN   i32 (i32.const 8))
    (global $KEYS_ARE_DOWN_LEFT_RIGHT_MASK i32 (i32.const  3))
    (global $KEYS_ARE_DOWN_UP_DOWN_MASK    i32 (i32.const 12))

    (global $SNAKE_MOVEMENT_PX_PER_S  f32 (f32.const 300))
    (global $SNAKE_RADIUS             f32 (f32.const 12))
    (global $ORB_RADIUS               f32 (f32.const 8))

    (global $GAME_STATE_FIRST_UPDATE i32 (i32.const 0))
    (global $GAME_STATE_START_SCREEN i32 (i32.const 1))
    (global $GAME_STATE_PLAYING      i32 (i32.const 2))
    (global $GAME_STATE_END_SCREEN   i32 (i32.const 3))

    ;; Read right to left because little edian :(
    (global $SNAKE_HEAD_COLOR    i32 (i32.const 0xFF11DD11))
    (global $SNAKE_TAIL_COLOR    i32 (i32.const 0xFF117711))
    (global $ORB_COLOR           i32 (i32.const 0xFFFF00EE))
    (global $ORB_HIGHLIGHT_COLOR i32 (i32.const 0xFFFFFFFF))
    (global $TEXT_COLOR          i32 (i32.const 0xFFFFAAFF))
    (global $BACKGROUND_COLOR    i32 (i32.const 0xFF000000))

    (global $INVERSE_SQRT_2 f32 (f32.const 0.7071067811865475))

    ;; Values are initialized in the "$reset_game" function
    (global $canvas_width                (mut i32) (i32.const  0))
    (global $canvas_height               (mut i32) (i32.const  0))
    (global $game_state                  (mut i32) (i32.const  0))
    (global $timestamp_update_call       (mut f32) (f32.const -1))
    (global $timestamp_last_update_call  (mut f32) (f32.const -1))
    (global $keys_are_down_mask          (mut i32) (i32.const  0))
    (global $snake_unit_heading_x        (mut f32) (f32.const  1))
    (global $snake_unit_heading_y        (mut f32) (f32.const  0))
    (global $snake_length                (mut f32) (f32.const  0))
    (global $snake_target_length         (mut f32) (f32.const -1))
    (global $score_100s_digit            (mut i32) (i32.const  0))
    (global $score_10s_digit             (mut i32) (i32.const  0))
    (global $score_1s_digit              (mut i32) (i32.const  0))
    (global $orb_x_as_canvas_width_frac  (mut f32) (f32.const -1))
    (global $orb_y_as_canvas_height_frac (mut f32) (f32.const -1))

    (func (export "update") (param $timestamp f32)
        (if (i32.eq (global.get $game_state) (global.get $GAME_STATE_FIRST_UPDATE)) (then
            call $reset_game
            (global.set $game_state (global.get $GAME_STATE_START_SCREEN))
            return
        ))

        (global.set $timestamp_last_update_call (global.get $timestamp_update_call))
        (global.set $timestamp_update_call (local.get $timestamp))

        (if (i32.eq (global.get $game_state) (global.get $GAME_STATE_START_SCREEN)) (then
            (call $draw_start_screen_text)
            return
        ))

        (if (i32.eq (global.get $game_state) (global.get $GAME_STATE_PLAYING)) (then
            call $snake_update

            (if (call $snake_check_circle_collides_with_head
                    (call $orb_calc_x) (call $orb_calc_y)
                    (global.get $ORB_RADIUS)
            ) (then
                call $score_inc
                call $orb_update
                call $snake_target_length_inc
            ))

            call $score_draw

            (if (call $snake_check_collision) (then
                (global.set $game_state (global.get $GAME_STATE_END_SCREEN))
            ))

            return
        ))

        (if (i32.eq (global.get $game_state) (global.get $GAME_STATE_END_SCREEN)) (then
            call $draw_end_screen_text
            return
        ))
    )

    (func (export "input_key") (param $action i32) (param $key i32)
        (local $latin1_32_byte_range_idx i32)
        (local $arrow_key i32)
        (local $key_down_mask i32)

        ;; Special handling of key presses while in the start and end screen
        (if (i32.or 
                (i32.eq
                    (global.get $GAME_STATE_START_SCREEN)
                    (global.get $game_state))
                (i32.and
                    (i32.eq
                        (global.get $GAME_STATE_END_SCREEN)
                        (global.get $game_state))
                    (i32.eq (local.get $key) (global.get $KEY_SPACE)))
        ) (then
            (call $reset_game)

            (global.set $game_state (global.get $GAME_STATE_PLAYING))

            call $orb_update
        ))

        ;; == Handle keys during play ==

        ;; Ignore keys that are not the 32-byte ranges with index
        ;;   2 (0x40-0x5F) for upper case letters
        ;;   3 (0x60-0x6F) for lower case letters
        ;;   4 (0x80-0x9F) for latin1 control codes -- we're using the for arrow keys
        (local.set $latin1_32_byte_range_idx
            (i32.shr_u (local.get $key) (i32.const 5)))
        (if (i32.lt_u (local.get $latin1_32_byte_range_idx) (i32.const 2)) (then
            return
        ))
        (if (i32.gt_u (local.get $latin1_32_byte_range_idx) (i32.const 4)) (then
            return
        ))

        ;; Calculate the arrow key code by masking the lower 5 bits of the
        ;; key code and setting the upper bits to those of the latin1
        ;; control codes (0x80).
        (local.set $arrow_key
            (i32.or
                (i32.and (local.get $key) (i32.const 0x1F))
                (i32.const 0x80)))

        ;; Determine the bit mask that signifies that a key is pressed down
        (if (i32.eq (local.get $arrow_key) (global.get $ARROW_UP)) (then
            (local.set $key_down_mask (global.get $KEY_IS_DOWN_UP))
        ))
        (if (i32.eq (local.get $arrow_key) (global.get $ARROW_LEFT)) (then
            (local.set $key_down_mask (global.get $KEY_IS_DOWN_LEFT))
        ))
        (if (i32.eq (local.get $arrow_key) (global.get $ARROW_DOWN)) (then
            (local.set $key_down_mask (global.get $KEY_IS_DOWN_DOWN))
        ))
        (if (i32.eq (local.get $arrow_key) (global.get $ARROW_RIGHT)) (then
            (local.set $key_down_mask (global.get $KEY_IS_DOWN_RIGHT))
        ))

        ;; Update the `$keys_are_down_mask` based on the bit mask for the key
        (if (i32.eq (local.get $action) (global.get $INPUT_UPDATE)) (then
            ;; If the  is a key press action the we can just directly
            ;; set the aggregate bit mask to that of the individual key
            (global.set $keys_are_down_mask (local.get $key_down_mask))
        ))
        (if (i32.eq (local.get $action) (global.get $INPUT_START)) (then
            ;; If the  is a key down action then we
            ;; a) set the "left" and "right" bits to 0 if left or right are down
            ;;    OR the "up" and "down" bits to 0 if up or down are down,
            ;;    to make sure that the opposite key's bit is set to 0,
            ;;    meaning that left will be registered even if right is down, etc.
            (if (i32.and
                    (global.get $KEYS_ARE_DOWN_LEFT_RIGHT_MASK)
                    (local.get $key_down_mask)
            )(then
                (global.set $keys_are_down_mask
                    (i32.and
                        (global.get $keys_are_down_mask)
                        (global.get $KEYS_ARE_DOWN_UP_DOWN_MASK)))
            ))
            (if (i32.and
                    (global.get $KEYS_ARE_DOWN_UP_DOWN_MASK)
                    (local.get $key_down_mask)
            ) (then
                (global.set $keys_are_down_mask
                    (i32.and
                        (global.get $keys_are_down_mask)
                        (global.get $KEYS_ARE_DOWN_LEFT_RIGHT_MASK)))
            ))
            ;; a) add the bit mask of the new key to the aggregate bit mask
            (global.set $keys_are_down_mask
                (i32.or 
                    (global.get $keys_are_down_mask)
                    (local.get $key_down_mask)))
        ))
        (if (i32.eq (local.get $action) (global.get $INPUT_END)) (then
            ;; If the  is a key up action then we set unset the key's
            ;; bit in the aggregate bit mask
            (global.set $keys_are_down_mask
                (i32.and
                    (global.get $keys_are_down_mask)
                    (i32.xor
                        (i32.const 0xF)
                        (local.get $key_down_mask))))
        ))

        ;; Update the coordinates of the snake's heading unit vector, based on the
        ;; aggregate bit mask
        (if (i32.and
                (global.get $keys_are_down_mask)
                (global.get $KEY_IS_DOWN_UP)
        ) (then
            (if (i32.and
                    (global.get $KEY_IS_DOWN_LEFT)
                    (global.get $keys_are_down_mask)
            ) (then
                (global.set $snake_unit_heading_x
                    (f32.mul (f32.const -1) (global.get $INVERSE_SQRT_2)))
                (global.set $snake_unit_heading_y
                    (f32.mul (f32.const -1) (global.get $INVERSE_SQRT_2)))
                return
            ))
            (if (i32.and
                    (global.get $KEY_IS_DOWN_RIGHT)
                    (global.get $keys_are_down_mask)
            ) (then
                (global.set $snake_unit_heading_x
                    (f32.mul (f32.const  1) (global.get $INVERSE_SQRT_2)))
                (global.set $snake_unit_heading_y
                    (f32.mul (f32.const -1) (global.get $INVERSE_SQRT_2)))
                return
            ))
            (global.set $snake_unit_heading_x (f32.const  0))
            (global.set $snake_unit_heading_y (f32.const -1))
            return
        ))
        (if (i32.and
                (global.get $KEY_IS_DOWN_DOWN)
                (global.get $keys_are_down_mask)
        ) (then
            (if (i32.and
                    (global.get $KEY_IS_DOWN_LEFT)
                    (global.get $keys_are_down_mask)
            ) (then
                (global.set $snake_unit_heading_x
                    (f32.mul (f32.const -1) (global.get $INVERSE_SQRT_2)))
                (global.set $snake_unit_heading_y
                    (f32.mul (f32.const  1) (global.get $INVERSE_SQRT_2)))
                return
            ))
            (if (i32.and
                    (global.get $KEY_IS_DOWN_RIGHT)
                    (global.get $keys_are_down_mask)
            ) (then
                (global.set $snake_unit_heading_x
                    (f32.mul (f32.const  1) (global.get $INVERSE_SQRT_2)))
                (global.set $snake_unit_heading_y
                    (f32.mul (f32.const  1) (global.get $INVERSE_SQRT_2)))
                return
            ))
            (global.set $snake_unit_heading_x (f32.const  0))
            (global.set $snake_unit_heading_y (f32.const  1))
            return
        ))
        (if (i32.and
                (global.get $KEY_IS_DOWN_LEFT)
                (global.get $keys_are_down_mask)
        ) (then
            (global.set $snake_unit_heading_x (f32.const -1))
            (global.set $snake_unit_heading_y (f32.const  0))
            return
        ))
        (if (i32.and
                (global.get $KEY_IS_DOWN_RIGHT)
                (global.get $keys_are_down_mask)
        ) (then
            (global.set $snake_unit_heading_x (f32.const  1))
            (global.set $snake_unit_heading_y (f32.const  0))
            return
        ))
    )

    (func (export "input_touch")
            (param $action i32) (param $x f32) (param $y f32)
        (local $dx f32)
        (local $dy f32)
        (local $abs_dx f32)
        (local $abs_dy f32)
        (local $denom f32)

        ;; Special handling of touch down while in the start and end screen
        (if (i32.and
                (i32.eq (global.get $INPUT_START) (local.get $action))
                (i32.or
                    (i32.eq
                        (global.get $GAME_STATE_START_SCREEN)
                        (global.get $game_state))
                    (i32.eq
                        (global.get $GAME_STATE_END_SCREEN)
                        (global.get $game_state)))
        ) (then
            (call $reset_game)

            (global.set $game_state (global.get $GAME_STATE_PLAYING))

            call $orb_update
            return
        ))

        (local.set $dx (f32.sub (local.get $x) (call $snake_buf_read_head_cx)))
        (local.set $dy (f32.sub (local.get $y) (call $snake_buf_read_head_cy)))
        (local.set $abs_dx (f32.abs (local.get $dx)))
        (local.set $abs_dy (f32.abs (local.get $dy)))
        (local.set $denom (f32.add (local.get $abs_dx) (local.get $abs_dy)))

        ;; 1. Calculate the unit heading based by deviding the change in
        ;;    x `$dx` and y `$dy` by a common denominator `$denom`.
        ;; 2. Gradually shrink `$denom` until the square root of the unit
        ;;    heading greater than or equal to 1.
        (loop $lp
            (global.set $snake_unit_heading_x
                (f32.div (local.get $dx) (local.get $denom)))
            (global.set $snake_unit_heading_y
                (f32.div (local.get $dy) (local.get $denom)))

            (local.set $denom (f32.mul (local.get $denom) (f32.const 0.99)))

            (f32.lt
                (f32.add
                    (f32.mul
                        (global.get $snake_unit_heading_x)
                        (global.get $snake_unit_heading_x))
                    (f32.mul
                        (global.get $snake_unit_heading_y)
                        (global.get $snake_unit_heading_y)))
                (f32.const 1.0))
            br_if $lp
        )
    )

    (func $resize_canvas (export "resize") (param $width i32) (param $height i32)
        (local $pages_n i32)

        (global.set $canvas_width (local.get $width))
        (global.set $canvas_height (local.get $height))

        ;; Calculate the number of bytes required to store the canvas RGBA data
        (global.set $memory_region_canvas_bytes_n
            (i32.mul
                (i32.mul (local.get $width) (local.get $height))
                (i32.const 4)))

        (local.set $pages_n
            (i32.sub
                (i32.add
                    (i32.div_u
                        (global.get $memory_region_canvas_bytes_n)
                        (i32.const 65536))
                    (i32.const 2))
                (memory.size)))

        (if (i32.gt_s (local.get $pages_n) (i32.const 0)) (then
            ;; Grow the linear memory to fit the RGBA data
            (memory.grow (local.get $pages_n)) drop
        ))

        (call $clear_canvas)

        (if (i32.eq (global.get $game_state) (global.get $GAME_STATE_PLAYING)) (then
            call $orb_draw
        ))
    )

    (func $reset_game
        (call $resize_canvas (global.get $canvas_width) (global.get $canvas_height))

        (call $snake_buf_reset)

        (global.set $snake_length (f32.const 0))
        (global.set $snake_target_length (f32.const 0))
        call $snake_target_length_inc
        (call $snake_buf_head_set
            (f32.div 
                (f32.convert_i32_s (global.get $canvas_width))
                (f32.const 2))
            (f32.div 
                (f32.convert_i32_s (global.get $canvas_height))
                (f32.const 2))
            (f32.const 0))
        (global.set $snake_unit_heading_x (f32.const 1))
        (global.set $snake_unit_heading_y (f32.const 0))

        (global.set $score_100s_digit (i32.const 0))
        (global.set $score_10s_digit  (i32.const 0))
        (global.set $score_1s_digit   (i32.const 0))

        (global.set $orb_x_as_canvas_width_frac  (f32.const -1))
        (global.set $orb_y_as_canvas_height_frac (f32.const -1))
        (call $orb_prng_seed (i32.const 0))
    )

    (func $snake_update
        (local $length_delta f32)
        (local $snake_head_x f32)
        (local $snake_head_y f32)

        ;; Calculate the change in movement based on the speed in px/s
        ;; and the time between updates
        (local.set $length_delta
            (f32.mul
                (global.get $SNAKE_MOVEMENT_PX_PER_S)
                (f32.mul
                    (f32.sub
                        (global.get $timestamp_update_call)
                        (global.get $timestamp_last_update_call))
                    (f32.const 0.001))))

        ;; Calculate the current position of the head based on
        ;; the last position and the "change in movement"
        (local.set $snake_head_x
            (call $mod_f32
                (f32.add
                    (call $snake_buf_read_head_cx)
                    (f32.mul
                        (global.get $snake_unit_heading_x)
                        (local.get $length_delta)))
                (f32.convert_i32_s (global.get $canvas_width))))
        (local.set $snake_head_y
            (call $mod_f32
                (f32.add
                    (call $snake_buf_read_head_cy)
                    (f32.mul
                        (global.get $snake_unit_heading_y)
                        (local.get $length_delta)))
                (f32.convert_i32_s (global.get $canvas_height))))

        (block $while (loop $lp
            (f32.le
                (global.get $snake_length)
                (global.get $snake_target_length))
            br_if $while

            (global.set $snake_length (f32.sub
                (global.get $snake_length)
                (call $snake_buf_read_tail_length_delta)))

            ;; Overdraw old tail circle with background color to visually
            ;; remove it from the canvas
            (call $fill_circle_f32
                (call $snake_buf_read_tail_cx)
                (call $snake_buf_read_tail_cy)
                (global.get $SNAKE_RADIUS)
                (global.get $BACKGROUND_COLOR))

            (call $snake_buf_tail_drop)
        ))

        ;; Redraw the new last tail circle in the snake tail color, to
        ;; avoid a cutout in the snake left by the overdrawing during the
        ;; above loop
        (call $fill_circle_f32
            (call $snake_buf_read_tail_cx)
            (call $snake_buf_read_tail_cy)
            (global.get $SNAKE_RADIUS)
            (global.get $SNAKE_TAIL_COLOR))

        ;; Add movement delta to length
        (global.set $snake_length
            (f32.add (global.get $snake_length) (local.get $length_delta)))

        ;; Overdraw the old snake head circle in the snake tail color, to
        ;; replace the snake head color for the last update call
        (call $fill_circle_f32
            (call $snake_buf_read_head_cx)
            (call $snake_buf_read_head_cy)
            (global.get $SNAKE_RADIUS)
            (global.get $SNAKE_TAIL_COLOR))
        ;; Draw the new snake head in brighter color so collisions are obvious
        (call $fill_circle_f32
            (local.get $snake_head_x)
            (local.get $snake_head_y)
            (global.get $SNAKE_RADIUS)
            (global.get $SNAKE_HEAD_COLOR))

        (call $snake_buf_head_push
            (local.get $snake_head_x)
            (local.get $snake_head_y)
            (local.get $length_delta))
    )

    (func $snake_check_collision (result i32)
        (local $circle_x f32)
        (local $circle_y f32)

        (call $snake_buf_read_ptr_point_to_tail)

        (loop $lp
            (local.set $circle_x (call $snake_buf_read_cx))
            (local.set $circle_y (call $snake_buf_read_cy))

            (call $snake_check_circle_collides_with_head
                (local.get $circle_x) (local.get $circle_y)
                (global.get $SNAKE_RADIUS))
            (if (then
                (i32.const 1)
                return
            ))

            (call $snake_buf_read_ptr_inc)

            (i32.eq (call $snake_buf_read_ptr_is_at_head) (i32.const 0))
            br_if $lp
        )

        (i32.const 0)
        return
    )

    (func $snake_check_circle_collides_with_head
            (param $cx f32) (param $cy f32)
            (param $r f32)
            (result i32)
        (if (i32.eq
                (call $check_point_is_infront
                    (call $snake_buf_read_head_cx) (call $snake_buf_read_head_cy)
                    (local.get $cx) (local.get $cy)
                    (global.get $snake_unit_heading_x) (global.get $snake_unit_heading_y))
                (i32.const 0)
        ) (then
            (return (i32.const 0))
        ))

        (call $check_circles_collide
            (call $snake_buf_read_head_cx) (call $snake_buf_read_head_cy)
            (global.get $SNAKE_RADIUS)
            (local.get $cx) (local.get $cy)
            (local.get $r))
    )

    (func $check_circles_collide
            (param $cx1 f32) (param $cy1 f32) (param $r1 f32)
            (param $cx2 f32) (param $cy2 f32) (param $r2 f32)
            (result i32)
        (local $delta_cx f32)
        (local $delta_cy f32)
        (local $sum_r f32)

        (local.set $delta_cx (f32.abs (f32.sub (local.get $cx2) (local.get $cx1))))
        (local.set $delta_cy (f32.abs (f32.sub (local.get $cy2) (local.get $cy1))))

        (local.set $sum_r (f32.add (local.get $r1) (local.get $r2)))

        (f32.lt
            (f32.add
                (f32.mul (local.get $delta_cx) (local.get $delta_cx))
                (f32.mul (local.get $delta_cy) (local.get $delta_cy)))
            (f32.mul (local.get $sum_r) (local.get $sum_r)))
    )

    (func $check_point_is_infront
            (param $origin_x f32) (param $origin_y f32)
            (param $px f32) (param $py f32)
            (param $direction_x f32) (param $direction_y f32)
            (result i32)
        (local $delta_x f32)
        (local $delta_y f32)

        (local.set $delta_x (f32.sub (local.get $px) (local.get $origin_x)))
        (local.set $delta_y (f32.sub (local.get $py) (local.get $origin_y)))

        ;; We just check that the scalar product is greater than 0
        (f32.gt
            (f32.add
                (f32.mul (local.get $direction_x) (local.get $delta_x))
                (f32.mul (local.get $direction_y) (local.get $delta_y)))
            (f32.const 0))
    )

    (func $snake_target_length_inc
        (global.set $snake_target_length
            (f32.add
                (global.get $snake_target_length)
                (f32.mul
                    (f32.const 0.05)
                    (f32.convert_i32_s
                        (i32.add
                            (global.get $canvas_width)
                            (global.get $canvas_height))))))
    )

    (func $orb_update
        (local $orb_x f32)
        (local $orb_y f32)
        (local $old_orb_x f32)
        (local $old_orb_y f32)
        (local $snake_circle_x f32)
        (local $snake_circle_y f32)

        (local.set $old_orb_x (call $orb_calc_x))
        (local.set $old_orb_y (call $orb_calc_y))

        ;; Loop until orb spawned at a coordinate that is NOT inside the snake
        (loop $outer_lp
            (global.set $orb_x_as_canvas_width_frac  (call $orb_prng_gen_0_to_1))
            (global.set $orb_y_as_canvas_height_frac (call $orb_prng_gen_0_to_1))
            (local.set $orb_x (call $orb_calc_x))
            (local.set $orb_y (call $orb_calc_y))

            (call $snake_buf_read_ptr_point_to_tail)

            (block $until (loop $inner_lp
                (local.set $snake_circle_x (call $snake_buf_read_cx))
                (local.set $snake_circle_y (call $snake_buf_read_cy))

                (call $check_circles_collide
                    (local.get $orb_x) (local.get $orb_y)
                    (global.get $ORB_RADIUS)
                    (local.get $snake_circle_x) (local.get $snake_circle_y)
                    (global.get $SNAKE_RADIUS))
                br_if $outer_lp

                (call $snake_buf_read_ptr_inc)

                (call $snake_buf_read_ptr_is_at_head)
                br_if $until

                br $inner_lp
            ))
        )

        ;; Over draw old orb with the background color if it existed,
        ;; removing the orb.
        ;; Non-existent orbs have coord values of -1
        (if (f32.ne (local.get $old_orb_x) (f32.const -1)) (then
            (call $fill_circle_f32
                (local.get $old_orb_x) (local.get $old_orb_y)
                (global.get $ORB_RADIUS)
                (global.get $BACKGROUND_COLOR))
        ))

        call $orb_draw
    )

    (func $orb_calc_x (result f32)
        (f32.mul
            (global.get $orb_x_as_canvas_width_frac)
            (f32.convert_i32_u (global.get $canvas_width)))
    )

    (func $orb_calc_y (result f32)
        (f32.mul
            (global.get $orb_y_as_canvas_height_frac)
            (f32.convert_i32_u (global.get $canvas_height)))
    )

    (func $orb_draw
        ;; Draw orb
        (call $fill_circle_f32
            (call $orb_calc_x) (call $orb_calc_y)
            (global.get $ORB_RADIUS)
            (global.get $ORB_COLOR))
        ;; Draw specular highlight
        (call $fill_circle_f32
            (f32.add
                (call $orb_calc_x)
                (f32.mul (f32.const  0.2) (global.get $ORB_RADIUS)))
            (f32.add
                (call $orb_calc_y)
                (f32.mul (f32.const -0.2) (global.get $ORB_RADIUS)))
            (f32.mul (f32.const 0.4) (global.get $ORB_RADIUS))
            (global.get $ORB_HIGHLIGHT_COLOR))
    )

    ;; We use a "multiplicative congruential generator" (MCG) to randomly
    ;; generating the x and y-coordinates of of the orbs. The MCG uses
    ;; m = 2^32 (and c = 0) where "mod m" implicitly implemented using the
    ;; wrapping behaviour of i32 integers. Additionally we only use the 16
    ;; most significant bits of the random value "$orb_mcg_r" because
    ;; less significant bits have a low period.

    ;; Value from "Steele GL, Vigna S. Computationally easy, spectrally good multipliers for congruential pseudorandom number generators. Softw Pract Exper. 2022; 52(2): 443–458. doi:10.1002/spe.3030", Table 4, 24-Bit value.
    (global $ORB_MCG_A i32 (i32.const 14971189))
    (global $ORB_SEED_PRIME i32 (i32.const 7919))

    (global $orb_mcg_r (mut i32) (i32.const 0))

    (func $orb_prng_seed (param $seed i32)
        ;; Avoid seed having bad entropy by multiplying by a
        ;; largish prime.
        (local.set $seed (i32.mul (local.get $seed) (global.get $ORB_SEED_PRIME)))
        ;; Avoid $seed being 0
        (i32.eq (local.get $seed) (i32.const 0))
        (if (then
            (local.set $seed (global.get $ORB_SEED_PRIME))
        ))

        (global.set $orb_mcg_r (local.get $seed))
    )

    (func $orb_prng_gen_0_to_1 (result f32)
        (global.set $orb_mcg_r
            (i32.mul (global.get $orb_mcg_r) (global.get $ORB_MCG_A)))
        (f32.sub 
            (f32.reinterpret_i32
                (i32.or
                    ;; `0x3f800000` sets the f32 exponent bits to 127,
                    ;; producing an exponent of 2^0=1
                    (i32.const 0x3f800000)
                    ;; We set the f32 mantissa bits to the most significant
                    ;; bits from the psuedorandom i32 number `$orb_mcg_r`.
                    ;; We shift right by 9 because:
                    ;;      1 sign bit + 8 exponent bits = 9 bits
                    (i32.shr_u (global.get $orb_mcg_r) (i32.const 9))))
            ;; The ored bits produces an f32 number between 1.0 and 2.0
            ;; so we need to subtract 1 to get a number between 0.0 and 1.0
            (f32.const 1))
    )

    (func $score_inc
        ;; Overdraw the old score with the background color, removing it
        (call $score_draw_colored (global.get $BACKGROUND_COLOR))

        (global.set $score_1s_digit
            (i32.add (global.get $score_1s_digit) (i32.const 1)))

        (if (i32.eq (global.get $score_1s_digit) (i32.const 10)) (then
            (global.set $score_1s_digit (i32.const 0))
            (global.set $score_10s_digit
                (i32.add (global.get $score_10s_digit) (i32.const 1)))

            (if (i32.eq (global.get $score_10s_digit) (i32.const 10)) (then
                (global.set $score_10s_digit (i32.const 0))
                (global.set $score_100s_digit
                    (i32.add (global.get $score_100s_digit) (i32.const 1)))
            ))
        ))

        ;; Draw the new, updated score
        (call $score_draw_colored (global.get $TEXT_COLOR))
    )

    (func $score_draw
        (call $score_draw_colored (global.get $TEXT_COLOR))
    )

    (func $score_draw_colored (param $color i32)
        (call $text_draw_start
            (f32.const 16)
            (f32.const 16)
            (f32.const 16)
            (local.get $color))
        global.get $FONT_S           call $text_draw_char
        global.get $FONT_C           call $text_draw_char
        global.get $FONT_O           call $text_draw_char
        global.get $FONT_R           call $text_draw_char
        global.get $FONT_E           call $text_draw_char
        global.get $FONT_SPACE       call $text_draw_char
        global.get $score_100s_digit call $text_draw_digit
        global.get $score_10s_digit  call $text_draw_digit
        global.get $score_1s_digit   call $text_draw_digit
    )

    (func $draw_start_screen_text
        (local $msg_len f32)
        (local $font_size f32)

        (local.set $msg_len   (f32.const 29))
        (local.set $font_size (f32.const 16))

        (call $text_draw_start
            (f32.sub
                (f32.div (f32.convert_i32_s (global.get $canvas_width)) (f32.const 2))
                (f32.div
                    (f32.mul (local.get $msg_len) (local.get $font_size))
                    (f32.const 2)))
            (f32.sub
                (f32.div (f32.convert_i32_s (global.get $canvas_height)) (f32.const 2))
                (f32.div (local.get $font_size) (f32.const 2)))
            (local.get $font_size)
            (global.get $TEXT_COLOR))
        global.get $FONT_P     call $text_draw_char
        global.get $FONT_R     call $text_draw_char
        global.get $FONT_E     call $text_draw_char
        global.get $FONT_S     call $text_draw_char
        global.get $FONT_S     call $text_draw_char
        global.get $FONT_SPACE call $text_draw_char
        global.get $FONT_A     call $text_draw_char
        global.get $FONT_SPACE call $text_draw_char
        global.get $FONT_K     call $text_draw_char
        global.get $FONT_E     call $text_draw_char
        global.get $FONT_Y     call $text_draw_char
        global.get $FONT_SPACE call $text_draw_char
        global.get $FONT_O     call $text_draw_char
        global.get $FONT_R     call $text_draw_char
        global.get $FONT_SPACE call $text_draw_char
        global.get $FONT_T     call $text_draw_char
        global.get $FONT_O     call $text_draw_char
        global.get $FONT_U     call $text_draw_char
        global.get $FONT_C     call $text_draw_char
        global.get $FONT_H     call $text_draw_char
        global.get $FONT_SPACE call $text_draw_char
        global.get $FONT_T     call $text_draw_char
        global.get $FONT_O     call $text_draw_char
        global.get $FONT_SPACE call $text_draw_char
        global.get $FONT_S     call $text_draw_char
        global.get $FONT_T     call $text_draw_char
        global.get $FONT_A     call $text_draw_char
        global.get $FONT_R     call $text_draw_char
        global.get $FONT_T     call $text_draw_char
    )

    (func $draw_end_screen_text
        (local $msg_len f32)
        (local $font_size f32)

        (local.set $msg_len   (f32.const 10))
        (local.set $font_size (f32.const 16))
        (call $text_draw_start
            (f32.sub
                (f32.div (f32.convert_i32_s (global.get $canvas_width)) (f32.const 2))
                (f32.div
                    (f32.mul (local.get $msg_len) (local.get $font_size))
                    (f32.const 2)))
            (f32.sub
                (f32.div (f32.convert_i32_s (global.get $canvas_height)) (f32.const 2))
                (f32.mul (local.get $font_size) (f32.const 4)))
            (local.get $font_size)
            (global.get $TEXT_COLOR))
        global.get $FONT_G           call $text_draw_char
        global.get $FONT_A           call $text_draw_char
        global.get $FONT_M           call $text_draw_char
        global.get $FONT_E           call $text_draw_char
        global.get $FONT_SPACE       call $text_draw_char
        global.get $FONT_O           call $text_draw_char
        global.get $FONT_V           call $text_draw_char
        global.get $FONT_E           call $text_draw_char
        global.get $FONT_R           call $text_draw_char
        global.get $FONT_EXCLAIMATION call $text_draw_char

        (local.set $msg_len   (f32.const 15))
        (local.set $font_size (f32.const 24))
        (call $text_draw_start
            (f32.sub
                (f32.div (f32.convert_i32_s (global.get $canvas_width)) (f32.const 2))
                (f32.div
                    (f32.mul (local.get $msg_len) (local.get $font_size))
                    (f32.const 2)))
            (f32.add
                (f32.div (f32.convert_i32_s (global.get $canvas_height)) (f32.const 2))
                (f32.mul (local.get $font_size) (f32.const 0)))
            (local.get $font_size)
            (global.get $TEXT_COLOR))
        global.get $FONT_F           call $text_draw_char
        global.get $FONT_I           call $text_draw_char
        global.get $FONT_N           call $text_draw_char
        global.get $FONT_A           call $text_draw_char
        global.get $FONT_L           call $text_draw_char
        global.get $FONT_SPACE       call $text_draw_char
        global.get $FONT_S           call $text_draw_char
        global.get $FONT_C           call $text_draw_char
        global.get $FONT_O           call $text_draw_char
        global.get $FONT_R           call $text_draw_char
        global.get $FONT_E           call $text_draw_char
        global.get $FONT_SPACE       call $text_draw_char
        global.get $score_100s_digit call $text_draw_digit
        global.get $score_10s_digit  call $text_draw_digit
        global.get $score_1s_digit   call $text_draw_digit

        (local.set $msg_len   (f32.const 31))
        (local.set $font_size (f32.const 16))
        (call $text_draw_start
            (f32.sub
                (f32.div (f32.convert_i32_s (global.get $canvas_width)) (f32.const 2))
                (f32.div
                    (f32.mul (local.get $msg_len) (local.get $font_size))
                    (f32.const 2)))
            (f32.sub
                (f32.div (f32.convert_i32_s (global.get $canvas_height)) (f32.const 2))
                (f32.mul (local.get $font_size) (f32.const -4)))
            (local.get $font_size)
            (global.get $TEXT_COLOR))
        global.get $FONT_P           call $text_draw_char
        global.get $FONT_R           call $text_draw_char
        global.get $FONT_E           call $text_draw_char
        global.get $FONT_S           call $text_draw_char
        global.get $FONT_S           call $text_draw_char
        global.get $FONT_SPACE       call $text_draw_char
        global.get $FONT_S           call $text_draw_char
        global.get $FONT_P           call $text_draw_char
        global.get $FONT_A           call $text_draw_char
        global.get $FONT_C           call $text_draw_char
        global.get $FONT_E           call $text_draw_char
        global.get $FONT_SPACE       call $text_draw_char
        global.get $FONT_O           call $text_draw_char
        global.get $FONT_R           call $text_draw_char
        global.get $FONT_SPACE       call $text_draw_char
        global.get $FONT_T           call $text_draw_char
        global.get $FONT_O           call $text_draw_char
        global.get $FONT_U           call $text_draw_char
        global.get $FONT_C           call $text_draw_char
        global.get $FONT_H           call $text_draw_char
        global.get $FONT_SPACE       call $text_draw_char
        global.get $FONT_T           call $text_draw_char
        global.get $FONT_O           call $text_draw_char
        global.get $FONT_SPACE       call $text_draw_char
        global.get $FONT_R           call $text_draw_char
        global.get $FONT_E           call $text_draw_char
        global.get $FONT_S           call $text_draw_char
        global.get $FONT_T           call $text_draw_char
        global.get $FONT_A           call $text_draw_char
        global.get $FONT_R           call $text_draw_char
        global.get $FONT_T           call $text_draw_char
    )


    ;; Snake Buffer
    ;; ----------------------------------------------------------------------

    (global $SNAKE_BUF_BYTES_PER_ITEM i32  (i32.const 12))
    (global $snake_buf_head_ptr  (mut i32) (i32.const -1))
    (global $snake_buf_tail_ptr  (mut i32) (i32.const -1))
    (global $snake_buf_read_ptr  (mut i32) (i32.const -1))

    (func $snake_buf_reset
        (global.set $snake_buf_head_ptr
            (global.get $memory_region_snake_buf_offset))
        (global.set $snake_buf_tail_ptr
            (global.get $memory_region_snake_buf_offset))
        (global.set $snake_buf_read_ptr
            (global.get $memory_region_snake_buf_offset))
    )

    (func $snake_buf_ptr_wrap (param $ptr i32) (result i32)
        ;; Calculate modulus
        (local $modulus i32)
        (local.set $modulus (i32.sub
            (global.get $memory_region_snake_buf_bytes_n)
            (i32.rem_u
                (global.get $memory_region_snake_buf_bytes_n)
                (global.get $SNAKE_BUF_BYTES_PER_ITEM))))
        
        ;; Subtract offset
        (local.set $ptr (i32.sub
            (local.get $ptr)
            (global.get $memory_region_snake_buf_offset)))

        ;; Perform modulo operation
        (local.set $ptr (i32.rem_u
            (local.get $ptr)
            (local.get $modulus)))

        ;; Add offset
        (local.set $ptr (i32.add
            (local.get $ptr)
            (global.get $memory_region_snake_buf_offset)))

        local.get $ptr
    )

    (func $snake_buf_ptr_inc (param $ptr i32) (result i32)
        (local.set $ptr (i32.add
            (local.get $ptr)
            (global.get $SNAKE_BUF_BYTES_PER_ITEM)))
        (call $snake_buf_ptr_wrap (local.get $ptr))
    )

    (func $snake_buf_ptr_dec (param $ptr i32) (result i32)
        (local.set $ptr (i32.sub
            (local.get $ptr)
            (global.get $SNAKE_BUF_BYTES_PER_ITEM)))
        (call $snake_buf_ptr_wrap (local.get $ptr))
    )

    (func $snake_buf_head_set
            (param $cx f32)
            (param $cy f32)
            (param $length_delta f32)
        (f32.store
            (i32.add (global.get $snake_buf_head_ptr) (i32.const 0))
            (local.get $cx))
        (f32.store
            (i32.add (global.get $snake_buf_head_ptr) (i32.const 4))
            (local.get $cy))
        (f32.store
            (i32.add (global.get $snake_buf_head_ptr) (i32.const 8))
            (local.get $length_delta))
    )

    (func $snake_buf_head_inc
        (global.set $snake_buf_head_ptr
            (call $snake_buf_ptr_inc
                (global.get $snake_buf_head_ptr)))
    )

    (func $snake_buf_head_push
            (param $cx f32)
            (param $cy f32)
            (param $length_delta f32)
        (call $snake_buf_head_inc)

        (call $snake_buf_head_set
            (local.get $cx)
            (local.get $cy)
            (local.get $length_delta)
        )
    )

    (func $snake_buf_tail_drop
        (global.set $snake_buf_tail_ptr
            (call $snake_buf_ptr_inc
                (global.get $snake_buf_tail_ptr)))
    )

    (func $snake_buf_read_cx (result f32)
        (f32.load (global.get $snake_buf_read_ptr))
    )

    (func $snake_buf_read_cy (result f32)
        (f32.load (i32.add
            (global.get $snake_buf_read_ptr)
            (i32.const 4)))
    )

    (func $snake_buf_read_length_delta (result f32)
        (f32.load (i32.add
            (global.get $snake_buf_read_ptr)
            (i32.const 8)))
    )

    (func $snake_buf_read_ptr_inc
        (global.set $snake_buf_read_ptr
            (call $snake_buf_ptr_inc (global.get $snake_buf_read_ptr)))
    )

    (func $snake_buf_read_ptr_dec
        (global.set $snake_buf_read_ptr
            (call $snake_buf_ptr_dec (global.get $snake_buf_read_ptr)))
    )

    (func $snake_buf_read_ptr_point_to_head
        (global.set $snake_buf_read_ptr (global.get $snake_buf_head_ptr))
    )

    (func $snake_buf_read_ptr_point_to_tail
        (global.set $snake_buf_read_ptr (global.get $snake_buf_tail_ptr))
    )

    (func $snake_buf_read_ptr_is_at_head (result i32)
        (i32.eq
            (global.get $snake_buf_read_ptr)
            (global.get $snake_buf_head_ptr))
    )

    (func $snake_buf_read_head_cx (result f32)
        ;; Record old read pointer position
        (local $old_read_ptr i32)
        (local $result f32)
        (local.set $old_read_ptr (global.get $snake_buf_read_ptr))

        ;; Set read pointer to head
        (call $snake_buf_read_ptr_point_to_head)
        (local.set $result (call $snake_buf_read_cx))

        ;; Restore old read pointer
        (global.set $snake_buf_read_ptr (local.get $old_read_ptr))

        local.get $result
    )

    (func $snake_buf_read_head_cy (result f32)
        ;; Record old read pointer position
        (local $old_read_ptr i32)
        (local $result f32)
        (local.set $old_read_ptr (global.get $snake_buf_read_ptr))

        ;; Set read pointer to head
        (call $snake_buf_read_ptr_point_to_head)
        (local.set $result (call $snake_buf_read_cy))

        ;; Restore old read pointer
        (global.set $snake_buf_read_ptr (local.get $old_read_ptr))

        local.get $result
    )

    (func $snake_buf_read_head_length_delta (result f32)
        ;; Record old read pointer position
        (local $old_read_ptr i32)
        (local $result f32)
        (local.set $old_read_ptr (global.get $snake_buf_read_ptr))

        ;; Set read pointer to head
        (call $snake_buf_read_ptr_point_to_head)
        (local.set $result (call $snake_buf_read_length_delta))

        ;; Restore old read pointer
        (global.set $snake_buf_read_ptr (local.get $old_read_ptr))

        local.get $result
    )

    (func $snake_buf_read_tail_cx (result f32)
        ;; Record old read pointer position
        (local $old_read_ptr i32)
        (local $result f32)
        (local.set $old_read_ptr (global.get $snake_buf_read_ptr))

        ;; Set read pointer to head
        (call $snake_buf_read_ptr_point_to_tail)
        (local.set $result (call $snake_buf_read_cx))

        ;; Restore old read pointer
        (global.set $snake_buf_read_ptr (local.get $old_read_ptr))

        local.get $result
    )

    (func $snake_buf_read_tail_cy (result f32)
        ;; Record old read pointer position
        (local $old_read_ptr i32)
        (local $result f32)
        (local.set $old_read_ptr (global.get $snake_buf_read_ptr))

        ;; Set read pointer to head
        (call $snake_buf_read_ptr_point_to_tail)
        (local.set $result (call $snake_buf_read_cy))

        ;; Restore old read pointer
        (global.set $snake_buf_read_ptr (local.get $old_read_ptr))

        local.get $result
    )

    (func $snake_buf_read_tail_length_delta (result f32)
        ;; Record old read pointer position
        (local $old_read_ptr i32)
        (local $result f32)
        (local.set $old_read_ptr (global.get $snake_buf_read_ptr))

        ;; Set read pointer to head
        (call $snake_buf_read_ptr_point_to_tail)
        (local.set $result (call $snake_buf_read_length_delta))

        ;; Restore old read pointer
        (global.set $snake_buf_read_ptr (local.get $old_read_ptr))

        local.get $result
    )


    ;; Canvas Implementation
    ;; ----------------------------------------------------------------------

    (func $calc_memory_region_canvas_bytes_n (result i32)
        (i32.mul
            (i32.mul (global.get $canvas_width) (global.get $canvas_height))
            (i32.const 4))
    )

    (func $set_pixel (param $x i32) (param $y i32) (param $color i32)
        (i32.store 
            (i32.add
                (global.get $memory_region_canvas_bytes_offset)
                (i32.mul
                    (i32.add
                        (i32.mul
                            (i32.add
                                (i32.sub (global.get $canvas_height) (local.get $y))
                                (i32.const -1))
                            (global.get $canvas_width))
                        (local.get $x))
                    (i32.const 4)))
            (local.get $color))
    )

    (func $fill_rect_i32
            (param $x     i32) (param $y      i32)
            (param $width i32) (param $height i32)
            (param $color i32)
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
        (if (call $is_outside_canvas
                (local.get $min_x) (local.get $min_y)
                (local.get $max_x) (local.get $max_y)
        )(then
            return
        ))

        ;; Clamp rect bounds inside of canvas
        (if (i32.lt_s (local.get $min_x) (i32.const 0)) (then
            (local.set $min_x (i32.const 0))
        ))
        (if (i32.lt_s (local.get $min_y) (i32.const 0)) (then
            (local.set $min_y (i32.const 0))
        ))
        (if (i32.gt_s (local.get $max_x) (global.get $canvas_width)) (then
            (local.set $max_x (i32.sub (global.get $canvas_width) (i32.const 1)))
        ))
        (if (i32.gt_s (local.get $max_y) (global.get $canvas_height)) (then
            (local.set $max_y (i32.sub (global.get $canvas_height) (i32.const 1)))
        ))

        (loop $y_lp
            (local.set $x (local.get $min_x))
            (loop $x_lp
                (call $set_pixel (local.get $x) (local.get $y) (local.get $color))

                (local.set $x (i32.add (local.get $x) (i32.const 1)))

                (i32.lt_s (local.get $x) (local.get $max_x))
                br_if $x_lp
            )

            (local.set $y (i32.add (local.get $y) (i32.const 1)))

            (i32.lt_s (local.get $y) (local.get $max_y))
            br_if $y_lp
        )
    )

    (func $fill_rect_f32
            (param $x     f32) (param $y      f32)
            (param $width f32) (param $height f32)
            (param $color i32)
        (local $x_i32 i32)
        (local $y_i32 i32)
        (local $width_i32 i32)
        (local $height_i32 i32)

        ;; We just truncate the values and call the i32 variant of
        ;; the function

        (local.set $x_i32      (i32.trunc_f32_s (local.get $x)))
        (local.set $y_i32      (i32.trunc_f32_s (local.get $y)))
        (local.set $width_i32  (i32.trunc_f32_s (local.get $width)))
        (local.set $height_i32 (i32.trunc_f32_s (local.get $height)))

        (call $fill_rect_i32
            (local.get $x_i32    ) (local.get $y_i32     )
            (local.get $width_i32) (local.get $height_i32)
            (local.get $color))
    )

    (func $fill_circle_i32
            (param $cx i32) (param $cy i32) (param $radius i32)
            (param $color i32)
        (local $byte_address i32)
        (local $x i32)
        (local $y i32)
        (local $dx i32)
        (local $dy i32)

        ;; Set circle bounds
        (local $min_x i32)
        (local $min_y i32)
        (local $max_x i32)
        (local $max_y i32)
        (local.set $min_x (i32.sub (local.get $cx) (local.get $radius)))
        (local.set $min_y (i32.sub (local.get $cy) (local.get $radius)))
        (local.set $max_x (i32.add (local.get $cx) (local.get $radius)))
        (local.set $max_y (i32.add (local.get $cy) (local.get $radius)))

        ;; Return if circle is outside of canvas
        (if (call $is_outside_canvas
                (local.get $min_x) (local.get $min_y)
                (local.get $max_x) (local.get $max_y)
        ) (then
            return
        ))

        ;; Clamp circle bounds inside of canvas
        (if (i32.lt_s (local.get $min_x) (i32.const 0)) (then
            (local.set $min_x (i32.const 0))
        ))
        (if (i32.lt_s (local.get $min_y) (i32.const 0)) (then
            (local.set $min_y (i32.const 0))
        ))
        (if (i32.gt_s (local.get $max_x) (global.get $canvas_width)) (then
            (local.set $max_x (i32.sub (global.get $canvas_width) (i32.const 1)))
        ))
        (if (i32.gt_s (local.get $max_y) (global.get $canvas_height)) (then
            (local.set $max_y (i32.sub (global.get $canvas_height) (i32.const 1)))
        ))

        (local.set $y (local.get $min_y))
        (loop $y_lp
            (local.set $x (local.get $min_x))
            (loop $x_lp
                ;; Only fill pixel if [(x - cx)^2 + (y - cy)^2] <= radius^2
                (local.set $dx (i32.sub (local.get $x) (local.get $cx)))
                (local.set $dy (i32.sub (local.get $y) (local.get $cy)))
                (if (i32.lt_s
                        (i32.add
                            (i32.mul (local.get $dx) (local.get $dx))
                            (i32.mul (local.get $dy) (local.get $dy)))
                        (i32.mul (local.get $radius) (local.get $radius))
                ) (then
                    (call $set_pixel (local.get $x) (local.get $y) (local.get $color))
                ))

                (local.set $x (i32.add (local.get $x) (i32.const 1)))

                (i32.lt_s (local.get $x) (local.get $max_x))
                br_if $x_lp
            )
            (local.set $y (i32.add (local.get $y) (i32.const 1)))

            (i32.lt_s (local.get $y) (local.get $max_y))
            br_if $y_lp
        )
    )

    (func $fill_circle_f32
            (param $cx f32) (param $cy f32) (param $radius f32)
            (param $color i32)
        (local $cx_i32 i32)
        (local $cy_i32 i32)
        (local $radius_i32 i32)

        ;; We just truncate the values and call the i32 variant of
        ;; the function

        (local.set $cx_i32     (i32.trunc_f32_s (local.get $cx)))
        (local.set $cy_i32     (i32.trunc_f32_s (local.get $cy)))
        (local.set $radius_i32 (i32.trunc_f32_s (local.get $radius)))

        (call $fill_circle_i32
            (local.get $cx_i32) (local.get $cy_i32) (local.get $radius_i32)
            (local.get $color))
    )

    (func $clear_canvas
        (call $fill_rect_i32
            (i32.const 0) (i32.const 0)
            (global.get $canvas_width) (global.get $canvas_height)
            (global.get $BACKGROUND_COLOR))
    )

    (func $is_outside_canvas
            (param $min_x i32) (param $min_y i32)
            (param $max_x i32) (param $max_y i32)
            (result i32)
        (if (i32.lt_s (local.get $max_x) (i32.const 0)) (then
            (return (i32.const 1))
        ))
        (if (i32.lt_s (local.get $max_y) (i32.const 0)) (then
            (return (i32.const 1))
        ))
        (if (i32.ge_s (local.get $min_x) (global.get $canvas_width)) (then
            (return (i32.const 1))
        ))
        (if (i32.ge_s (local.get $min_y) (global.get $canvas_height)) (then
            (return (i32.const 1))
        ))

        (return (i32.const 0))
    )


    ;; Text Drawing
    ;; ----------------------------------------------------------------------

    (global $text_char_x (mut f32) (f32.const 0))
    (global $text_char_y (mut f32) (f32.const 0))
    (global $text_size   (mut f32) (f32.const 0))
    (global $text_color  (mut i32) (i32.const 0))

    (func $text_draw_start
            (param $x f32)
            (param $y f32)
            (param $size f32)
            (param $color i32)
        (global.set $text_char_x (local.get $x))
        (global.set $text_char_y (local.get $y))
        (global.set $text_size   (local.get $size))
        (global.set $text_color  (local.get $color))
    )

    (func $text_draw_char (param $font_embedding i64)
        (local $pixel_size f32)

        (local.set $pixel_size
            (f32.div (global.get $text_size) (f32.const 8)))

        ;; Draw scaled black font character raster first for the outline
        (call $text_draw_char_raster 
            (local.get $font_embedding)
            (local.get $pixel_size)
            (f32.const 2)
            (global.get $BACKGROUND_COLOR))

        ;; Then draw the actual font character raster
        (call $text_draw_char_raster 
            (local.get $font_embedding)
            (local.get $pixel_size)
            (f32.const 1)
            (global.get $text_color))

        (global.set $text_char_x
            (f32.add (global.get $text_char_x)
            (f32.mul (local.get $pixel_size) (f32.const 8))))
    )

    (func $text_draw_char_raster
            (param $font_embedding i64)
            (param $pixel_size f32)
            (param $scale_pixels f32)
            (param $color i32)
        (local $scaled_pixel_size f32)
        (local $scaled_pixel_offset f32)
        (local $row f32)
        (local $col f32)

        (local.set $scaled_pixel_size
            (f32.mul (local.get $pixel_size) (local.get $scale_pixels)))
        (local.set $scaled_pixel_offset
            (f32.mul
                (f32.sub (local.get $pixel_size) (local.get $scaled_pixel_size))
                (f32.const 0.5)))

        (local.set $row (f32.const 0))
        (local.set $col (f32.const 0))
        (loop $lp
            (if (i32.wrap_i64 (i64.and (local.get $font_embedding) (i64.const 1))) (then
                (call $fill_rect_f32
                    (f32.add
                        (global.get $text_char_x)
                        (f32.add
                            (f32.mul (local.get $col) (local.get $pixel_size))
                            (local.get $scaled_pixel_offset)))
                    (f32.add
                        (global.get $text_char_y)
                        (f32.add
                            (f32.mul (local.get $row) (local.get $pixel_size))
                            (local.get $scaled_pixel_offset)))
                    (local.get $scaled_pixel_size)
                    (local.get $scaled_pixel_size)
                    (local.get $color))
            ))

            (local.set $font_embedding
                (i64.shr_u (local.get $font_embedding)
                (i64.const 1)))

            (if (f32.lt (local.get $col) (f32.const 6.5)) (then
                (local.set $col (f32.add (local.get $col) (f32.const 1)))
            ) (else
                (local.set $row (f32.add (local.get $row) (f32.const 1)))
                (local.set $col (f32.const 0))
            ))

            (f32.lt (local.get $row) (f32.const 7.5))
            br_if $lp
        )
    )

    (func $text_draw_digit (param $digit i32)
        (if (i32.eq (local.get $digit) (i32.const 0)) (then
            (return (call $text_draw_char (global.get $FONT_0)))
        ))
        (if (i32.eq (local.get $digit) (i32.const 1)) (then
            (return (call $text_draw_char (global.get $FONT_1)))
        ))
        (if (i32.eq (local.get $digit) (i32.const 2)) (then
            (return (call $text_draw_char (global.get $FONT_2)))
        ))
        (if (i32.eq (local.get $digit) (i32.const 3)) (then
            (return (call $text_draw_char (global.get $FONT_3)))
        ))
        (if (i32.eq (local.get $digit) (i32.const 4)) (then
            (return (call $text_draw_char (global.get $FONT_4)))
        ))
        (if (i32.eq (local.get $digit) (i32.const 5)) (then
            (return (call $text_draw_char (global.get $FONT_5)))
        ))
        (if (i32.eq (local.get $digit) (i32.const 6)) (then
            (return (call $text_draw_char (global.get $FONT_6)))
        ))
        (if (i32.eq (local.get $digit) (i32.const 7)) (then
            (return (call $text_draw_char (global.get $FONT_7)))
        ))
        (if (i32.eq (local.get $digit) (i32.const 8)) (then
            (return (call $text_draw_char (global.get $FONT_8)))
        ))
        (if (i32.eq (local.get $digit) (i32.const 9)) (then
            (return (call $text_draw_char (global.get $FONT_9)))
        ))
    )


    ;; Character Codes
    ;; ----------------------------------------------------------------------

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
    (global $CHAR_A i32 (i32.const 65))
    (global $CHAR_D i32 (i32.const 68))
    (global $CHAR_S i32 (i32.const 83))
    (global $CHAR_W i32 (i32.const 87))
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


    ;; Font Embedding
    ;; ----------------------------------------------------------------------

    ;; -- font embedding start --
    (global $FONT_SPACE i64 (i64.const 0))
    (global $FONT_0 i64 (i64.const 4342110275762273280))
    (global $FONT_1 i64 (i64.const 4039746526926868480))
    (global $FONT_2 i64 (i64.const 9079886045385997312))
    (global $FONT_3 i64 (i64.const 4342103601079008256))
    (global $FONT_4 i64 (i64.const 2314988902226599936))
    (global $FONT_5 i64 (i64.const 4342103635400998400))
    (global $FONT_6 i64 (i64.const 4342105824827815936))
    (global $FONT_7 i64 (i64.const 289365141412150784))
    (global $FONT_8 i64 (i64.const 4342105817315687424))
    (global $FONT_9 i64 (i64.const 2026690734748482560))
    (global $FONT_A i64 (i64.const 4774451665011096576))
    (global $FONT_B i64 (i64.const 4486221013981478400))
    (global $FONT_C i64 (i64.const 4342035198389664768))
    (global $FONT_E i64 (i64.const 9079822126638333440))
    (global $FONT_F i64 (i64.const 144680465935269376))
    (global $FONT_G i64 (i64.const 4342106048170179584))
    (global $FONT_H i64 (i64.const 4774451665011098112))
    (global $FONT_I i64 (i64.const 2019873263463177216))
    (global $FONT_K i64 (i64.const 4765391207354483200))
    (global $FONT_L i64 (i64.const 9079822006379217408))
    (global $FONT_M i64 (i64.const 4774451407718072832))
    (global $FONT_N i64 (i64.const 4774486660539105792))
    (global $FONT_O i64 (i64.const 4342105843085491200))
    (global $FONT_P i64 (i64.const 144680604452142592))
    (global $FONT_R i64 (i64.const 4765391414320315904))
    (global $FONT_S i64 (i64.const 4342103617214495744))
    (global $FONT_T i64 (i64.const 1157442765409287680))
    (global $FONT_U i64 (i64.const 4342105843085492736))
    (global $FONT_V i64 (i64.const 145815110936576512))
    (global $FONT_Y i64 (i64.const 1157442765815316992))
    (global $FONT_EXCLAIMATION i64 (i64.const 144117395722732032))
    ;; -- font embedding end --


    ;; Logger Implementation
    ;; ----------------------------------------------------------------------

    (global $log_msg_len (mut i32) (i32.const 0))

    ;; Store a latin1 character code as a byte at the next position
    ;; in the logging memory.
    (func $log_char (param $char_code i32)
        (i32.store8
            (i32.add
                (global.get $memory_region_log_bytes_offset
                (global.get $log_msg_len)))
            (local.get $char_code))

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
        (call $extern_log (global.get $log_msg_len))

        (global.set $log_msg_len (i32.const 0))
    )


    ;; Math Helpers
    ;; ----------------------------------------------------------------------

    (func $mod_f32 (param $x f32) (param $m f32) (result f32)
        (local $remainder f32)

        (local.set $remainder
            (f32.sub
                (local.get $x)
                (f32.mul
                    (f32.floor
                        (f32.div
                            (local.get $x)
                            (local.get $m)))
                    (local.get $m))))

        (f32.lt (local.get $remainder) (f32.const 0))
        (if (then
            (f32.sub (local.get $m) (local.get $remainder))
            return
        ))

        local.get $remainder
        return
    )
)

