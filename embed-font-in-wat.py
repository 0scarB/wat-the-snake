#!/bin/python3

FONT_FILE = "./src/font.txt"
WAT_FILE = "./src/snake.wat"
UNSET_BIT_CHAR = "."
SET_BIT_CHAR = "#"
EMBEDDING_BEFORE = ";; -- font embedding start --"
EMBEDDING_AFTER = ";; -- font embedding end --"


def main():
    print(f"[Font Embedding] Parsing {FONT_FILE}...")
    with open(FONT_FILE, "rb") as font_file_handle:
        char_to_i64_dict = parse_font_file(font_file_handle)
    print(f"[Font Embedding] Parsed.")

    print(f"[Font Embedding] Generating WAT code...")
    wat_code = gen_wat_code_from_char_to_i64_dict(char_to_i64_dict)
    print(f"[Font Embedding] Generated code.")

    print(f"[Font Embedding] Embedding generated WAT code in {WAT_FILE}...")
    with open(WAT_FILE, "r+") as wat_file_handle:
        embed_generated_code(wat_file_handle, wat_code)
    print(f"[Font Embedding] Embeded code.")


# Font Parsing
# ----------------------------------------------------------------------

def parse_font_file(font_file_handle):
    char_to_i64_dict = {}
    font_file_line = 1
    while True:
        is_end_of_file = len(font_file_handle.read(1)) == 0
        if is_end_of_file:
            break
        else:
            # Move back 1 byte because we peeked 1 byte to check of EOF
            font_file_handle.seek(-1, 1)

        char, font_file_line = \
                parse_font_file_char_line(font_file_handle, font_file_line)
        i64_value, font_file_line = \
                parse_font_bits(font_file_handle, font_file_line)

        char_to_i64_dict[char] = i64_value

    return char_to_i64_dict


def parse_font_file_char_line(font_file_handle, font_file_line):
    line = font_file_handle.readline()
    assert line[0] == ord("'"), f"{FONT_FILE}:{font_file_line}:0 Expected \"'\"!"
    char = chr(line[1])
    assert line[2] == ord("'"), f"{FONT_FILE}:{font_file_line}:2 Expected \"'\"!"
    assert line[3] == ord('\n'), f"{FONT_FILE}:{font_file_line}:3 Expected end of line!"

    return (char, font_file_line + 1)


def parse_font_bits(font_file_handle, font_file_line):
    i64_value = 0
    for _ in range(8):
        byte_value, font_file_line = \
                parse_font_bits_line(font_file_handle, font_file_line)
        i64_value = (i64_value >> 8) | byte_value

    return i64_value, font_file_line


def parse_font_bits_line(font_file_handle, font_file_line):
    line = font_file_handle.readline()
    i64_value = 0
    for (col, char_code) in enumerate(line):
        if col == 15:
            assert char_code == ord('\n'), \
                    f"${FONT_FILE}:{font_file_line}:{col} Expected end of line"
            break

        if (col % 2) == 0:
            if char_code == ord(UNSET_BIT_CHAR):
                i64_value >>= 1
            elif char_code == ord(SET_BIT_CHAR):
                i64_value = (i64_value >> 1) | (1 << 64)
            else:
                assert False, \
                        f"{FONT_FILE}:{font_file_line}:{col} " \
                        f"Expected '{UNSET_BIT_CHAR}' or '{SET_BIT_CHAR}'"
        else:
            assert char_code == ord(' '), \
                    f"{FONT_FILE}:{font_file_line}:{col} Expected single space"

    return (i64_value, font_file_line + 1)


# WAT (WebAssembly Text Format) Code Generation
# ----------------------------------------------------------------------

def gen_wat_code_from_char_to_i64_dict(char_to_i64_dict):
    lines = []
    for (char, i64) in char_to_i64_dict.items():
        wat_global_name = f"$FONT_{char}"
        if char == ' ':
            wat_global_name = f"$FONT_SPACE"
        lines.append(f"    (global {wat_global_name} i64 (i64.const {i64}))")

    return "\n".join(lines) + "\n"


# Embedding
# ----------------------------------------------------------------------

def embed_generated_code(wat_file_handle, generated_code):
    state = "before"
    new_lines = []
    for line in wat_file_handle.readlines():
        if line.endswith(EMBEDDING_BEFORE + "\n"):
            new_lines.append(line)
            new_lines.append(generated_code)
            state = "in"
        if line.endswith(EMBEDDING_AFTER + "\n"):
            state = "after"

        if state != "in":
            new_lines.append(line)

    wat_file_handle.seek(0)
    wat_file_handle.writelines(new_lines)
    wat_file_handle.truncate()


# ----------------------------------------------------------------------


if __name__ == "__main__":
    main()

