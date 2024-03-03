(module
    (global $canvas_width  (import "imports" "canvasWidth" ) i32)
    (global $canvas_height (import "imports" "canvasHeight") i32)

    (memory $memory 16 4096)
    (export "memory" (memory $memory))
    (global $memory_log_region_bytes_n i32 (i32.const 1024))
    (export "memoryLogRegionBytesN" (global $memory_log_region_bytes_n))

    (func $log_extern (import "imports" "logFromNBytesOfMemory") (param i32))


    ;; Logger Implementation
    ;; ----------------------------------------------------------------------

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

    ;; Memory byte addres of the next character to be logged
    (global $log_msg_byte_idx (mut i32) (i32.const 0))

    ;; Store a latin1 character code as a byte at the next position
    ;; in the logging memory.
    (func $log_char (param $char_code i32)
        global.get $log_msg_byte_idx
        local.get $char_code
        i32.store

        global.get $log_msg_byte_idx
        i32.const 1
        i32.add
        global.set $log_msg_byte_idx
    )

    ;; Store the latin1 character codes of the digits in an i32 integer
    ;; at the next positions in the logging memory.
    (func $log_i32 (param $x i32)
        (local $factor_10 i32)
        (local $most_significant_digit i32)

        ;; Set factor_10 to 10^places where places is the number of
        ;; digits (in base 10) in x
        i32.const 1
        local.set $factor_10
        (loop $lp
            ;; factor_10 *= 10
            local.get $factor_10
            i32.const 10
            i32.mul
            local.set $factor_10

            ;; loop while x/factor_10 > 9
            local.get $x
            local.get $factor_10
            i32.div_s
            i32.const 9
            i32.gt_s
            br_if $lp
        )

        ;; Store the characters of the digits from x (in base 10) in
        ;; the logging memory in order from the most significant digit to
        ;; the least
        (loop $lp
            ;; Calculate the most siginifcant digit (in base 10):
            ;;      most_significant_digit = x/factor_10
            local.get $x
            local.get $factor_10
            i32.div_s
            local.set $most_significant_digit

            ;; Store the latin1 character code of the most significant digit 
            ;; in the logging memeory:
            ;;      log_char(most_significant_digit + CHAR_0)
            local.get $most_significant_digit
            global.get $CHAR_0
            i32.add
            call $log_char

            ;; Remove the most significant digit (in base 10) from x:
            ;;      x -= most_significant_digit*factor_10
            local.get $x
            local.get $most_significant_digit
            local.get $factor_10
            i32.mul
            i32.sub
            local.set $x

            ;; factor_10 /= 10
            local.get $factor_10
            i32.const 10
            i32.div_s
            local.set $factor_10

            ;; loop while factor_10 > 0
            local.get $factor_10
            i32.const 0
            i32.gt_s
            br_if $lp
        )
    )

    ;; 1. Call the external function $log_extern(<number of bytes in log message>),
    ;;    triggering the external logger to log based on the bytes stored in the
    ;;    logging memory region.
    ;; 2. Reset the index of the byte of the next log character
    (func $log_flush (param)
        global.get $log_msg_byte_idx
        call $log_extern

        i32.const 0
        global.set $log_msg_byte_idx
    )


    ;; Canvas Implementation
    ;; ----------------------------------------------------------------------

    ;; Fill the whole canvas with the color from the RGBA channel values
    (func $fill_canvas (param $r i32) (param $g i32) (param $b i32) (param $a i32)
        (local $rgba_byte_idx i32)
        (local $rgba_bytes_n i32)

        ;; rgba_byte_idx = 0
        i32.const 0
        local.set $rgba_byte_idx

        ;; rgba_byte_idx = canvas_width*canvas_height*4
        global.get $canvas_width
        global.get $canvas_height
        i32.mul
        i32.const 4
        i32.mul
        local.set $rgba_bytes_n

        (loop $lp
            ;; Set the byte value of the relevant channel
            (block $set_rgba_channel
                local.get $rgba_byte_idx
                i32.const 4
                i32.rem_s
                i32.const 0
                i32.eq
                (if (then
                    global.get $memory_log_region_bytes_n
                    local.get $rgba_byte_idx
                    i32.add
                    local.get $r
                    i32.store

                    br $set_rgba_channel
                ))

                local.get $rgba_byte_idx
                i32.const 4
                i32.rem_s
                i32.const 1
                i32.eq
                (if (then
                    global.get $memory_log_region_bytes_n
                    local.get $rgba_byte_idx
                    i32.add
                    local.get $g
                    i32.store

                    br $set_rgba_channel
                ))

                local.get $rgba_byte_idx
                i32.const 4
                i32.rem_s
                i32.const 2
                i32.eq
                (if (then
                    global.get $memory_log_region_bytes_n
                    local.get $rgba_byte_idx
                    i32.add
                    local.get $b
                    i32.store

                    br $set_rgba_channel
                ))

                local.get $rgba_byte_idx
                i32.const 4
                i32.rem_s
                i32.const 3
                i32.eq
                (if (then
                    global.get $memory_log_region_bytes_n
                    local.get $rgba_byte_idx
                    i32.add
                    local.get $a
                    i32.store

                    br $set_rgba_channel
                ))
            )

            ;; rgba_byte_idx += 1
            local.get $rgba_byte_idx
            i32.const 1
            i32.add
            local.set $rgba_byte_idx

            ;; loop while rgba_byte_idx < rgba_bytes_n
            local.get $rgba_byte_idx
            local.get $rgba_bytes_n
            i32.lt_s
            br_if $lp
        )
    )

    (func (export "main")
        ;; Log canvas width
        global.get $CHAR_c     call $log_char
        global.get $CHAR_a     call $log_char
        global.get $CHAR_n     call $log_char
        global.get $CHAR_v     call $log_char
        global.get $CHAR_a     call $log_char
        global.get $CHAR_s     call $log_char
        global.get $CHAR_SPACE call $log_char
        global.get $CHAR_w     call $log_char
        global.get $CHAR_i     call $log_char
        global.get $CHAR_d     call $log_char
        global.get $CHAR_t     call $log_char
        global.get $CHAR_h     call $log_char
        global.get $CHAR_COLON call $log_char
        global.get $CHAR_SPACE call $log_char
        global.get $canvas_width
        call $log_i32
        call $log_flush

        ;; Log canvas height
        global.get $CHAR_c     call $log_char
        global.get $CHAR_a     call $log_char
        global.get $CHAR_n     call $log_char
        global.get $CHAR_v     call $log_char
        global.get $CHAR_a     call $log_char
        global.get $CHAR_s     call $log_char
        global.get $CHAR_SPACE call $log_char
        global.get $CHAR_h     call $log_char
        global.get $CHAR_e     call $log_char
        global.get $CHAR_i     call $log_char
        global.get $CHAR_g     call $log_char
        global.get $CHAR_h     call $log_char
        global.get $CHAR_t     call $log_char
        global.get $CHAR_COLON call $log_char
        global.get $CHAR_SPACE call $log_char
        global.get $canvas_height
        call $log_i32
        call $log_flush

        ;; Fill canvas with color: rgba(63, 127, 191, 255)
        i32.const 63
        i32.const 127
        i32.const 191
        i32.const 255
        call $fill_canvas
    )
)

