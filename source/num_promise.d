module num_promise;

struct NumPromise {
	enum Type {
		MODIFIER, // %lo(symbol)
		LABEL, // l: -> l
		LITERAL, // 1
		PREFIXOP, // -1
		INFIXOP // 1+1
	}

	Type type;
	union {
		Modifier modifier;
		string label;
		int literal; // 32 bits
		PrefixOp prefix;
		InfixOp infix;
	}

	this(int value) {
		this.type = LITERAL;
		this.literal = value;
	}

	this(PrefixOp po) {
		this.type = PREFIXOP;
		this.prefix = po;
	}
}

struct PrefixOp {
	enum Type {
		NEGATE, // -
		COMPLEMENT // ~
	}

	Type type;
	Numpromise arg;
}

struct InfixOp {
	enum Type {
		// Precedence 2
		MULT, // *
		DIV, // /
		REMAINDER, // %
		SHIFT_LEFT, // <<
		SHIFT_RIGHT, // >>
		// Precedence 3
		OR, // |
		AND, // &
		XOR, // ^
		OR_NOT, // !
		// Precedence 4
		ADD, // +
		SUB, // -
		// Note, true yiels -1, false yields 0
		EQUAL, // ==
		NOT_EQUAL, // <> or !=
		LESS, // <
		MORE, // >
		MORE_EQUAL, // >=
		LESS_EQUAL, // <=
		// Precedence 5
		// Note, true yields 1, false yields 0
		LOGIC_AND, // &&
		LOGIC_OR // ||
		// VERBATIM quote:
		// In short, it’s only meaningful to add or subtract the offsets in an address; you can only have a defined section in one of the two arguments.
		// Will ignore & not restrain.
	}

	Type type;
	NumPromise argL;
	NumPromise argR;
}
