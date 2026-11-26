package luabind

count_tokens :: proc(src: string) -> int {
	n := 0
	i := 0

	for i < len(src) {
		ch := src[i]

		switch {
		case ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r':
			i += 1
		case ch == '-' && i + 1 < len(src) && src[i + 1] == '-':
			i = skip_comment(src, i + 2)
		case ch == '"' || ch == '\'':
			i = skip_quoted(src, i)
			n += 1
		case ch == '[' && long_bracket_level(src, i) >= 0:
			i = skip_long(src, i)
			n += 1
		case is_digit(ch) || (ch == '.' && i + 1 < len(src) && is_digit(src[i + 1])):
			i = skip_number(src, i)
			n += 1
		case is_name_char(ch):
			start := i
			for i < len(src) && is_name_char(src[i]) {
				i += 1
			}
			word := src[start:i]
			if word != "end" && word != "local" {
				n += 1
			}
		case:
			size, cost := operator(src[i:])
			i += size
			n += cost
		}
	}

	return n
}

@(private)
is_digit :: proc(ch: u8) -> bool {
	return ch >= '0' && ch <= '9'
}

@(private)
is_name_char :: proc(ch: u8) -> bool {
	return is_digit(ch) || ch == '_' || (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || ch >= 0x80
}

@(private)
operator :: proc(s: string) -> (size, cost: int) {
	if len(s) >= 3 && s[:3] == "..." {
		return 3, 1
	}

	if len(s) >= 2 {
		switch s[:2] {
		case "..", "==", "~=", "<=", ">=", "//", "::", "<<", ">>":
			return 2, 1
		}
	}

	switch s[0] {
	case ',', '.', ';', ':', ')', ']', '}':
		return 1, 0
	}
	return 1, 1
}

@(private)
long_bracket_level :: proc(src: string, i: int) -> int {
	j := i + 1
	for j < len(src) && src[j] == '=' {
		j += 1
	}
	if j < len(src) && src[j] == '[' {
		return j - i - 1
	}
	return -1
}

@(private)
skip_long :: proc(src: string, i: int) -> int {
	level := long_bracket_level(src, i)
	j := i + level + 2

	for j < len(src) {
		if src[j] == ']' {
			k := j + 1
			for k < len(src) && src[k] == '=' {
				k += 1
			}
			if k < len(src) && src[k] == ']' && k - j - 1 == level {
				return k + 1
			}
		}
		j += 1
	}
	return len(src)
}

@(private)
skip_comment :: proc(src: string, i: int) -> int {
	if i < len(src) && src[i] == '[' && long_bracket_level(src, i) >= 0 {
		return skip_long(src, i)
	}

	j := i
	for j < len(src) && src[j] != '\n' {
		j += 1
	}
	return j
}

@(private)
skip_quoted :: proc(src: string, i: int) -> int {
	quote := src[i]
	j := i + 1

	for j < len(src) {
		switch src[j] {
		case '\\':
			j += 2
		case quote:
			return j + 1
		case '\n':
			return j 
		case:
			j += 1
		}
	}
	return len(src)
}

@(private)
skip_number :: proc(src: string, i: int) -> int {
	hex := i + 1 < len(src) && src[i] == '0' && (src[i + 1] == 'x' || src[i + 1] == 'X')
	j := i

	for j < len(src) {
		ch := src[j]
		prev := src[j - 1] if j > i else 0
		exp := (prev == 'p' || prev == 'P') if hex else (prev == 'e' || prev == 'E')

		if is_name_char(ch) || ch == '.' || ((ch == '+' || ch == '-') && exp) {
			j += 1
		} else {
			break
		}
	}
	return j
}
