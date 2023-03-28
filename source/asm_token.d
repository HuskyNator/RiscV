module asm_token;

struct AsmToken {
	enum Type {
		LABEL,
		DIRECTIVE,
		INSTRUCTION,
		COMMENT
	}
}
