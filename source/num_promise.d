module num_promise;

class NumPromise {
	enum Type {
		MODIFIER, // %lo(symbol)
		LABEL, // l: -> l
		LITERAL, // 1
		PREFIXOP, // -1
		INFIXOP // 1+1
	}

	Type type;
	union {
		// Modifier modifier; TODO
		string label;
		int literal; // 32 bits
		PrefixOp prefix;
		InfixOp infix;
	}

	this(int value) {
		this.type = Type.LITERAL;
		this.literal = value;
	}

	this(PrefixOp po) {
		this.type = Type.PREFIXOP;
		this.prefix = po;
	}

	this(InfixOp io) {
		this.type = Type.INFIXOP;
		this.infix = io;
	}

	bool opEquals(R)(const R other) const {
		if (this.type != other.type)
			return false;
		if (this.type == Type.LABEL)
			return this.label == other.label;
		else if (this.type == Type.LITERAL)
			return this.literal == other.literal;
		else if (this.type == Type.PREFIXOP)
			return this.prefix == other.prefix;
		else if (this.type == Type.INFIXOP)
			return this.infix == other.infix;
		else
			return false;
	}

	override string toString() const pure nothrow {
		import std.conv : to;

		if (this.type == Type.LABEL)
			return this.label;
		else if (this.type == Type.LITERAL)
			return to!string(this.literal);
		else if (this.type == Type.PREFIXOP)
			return this.prefix.toString;
		else if (this.type == Type.INFIXOP)
			return this.infix.toString;
		else if (this.type == Type.MODIFIER)
			return "Modifier"; // TODO
		assert(0, "Invalid NumPromise type");
	}
}

struct PrefixOp {
	enum Type {
		NEGATE, // -
		COMPLEMENT // ~
	}

	Type type;
	NumPromise arg;

	bool opEquals(R)(const R other) const {
		return this.type == other.type && this.arg == other.arg;
	}

	string toString() const pure nothrow {
		import std.conv : to;

		try
			return type.to!string ~ '(' ~ arg.toString ~ ')';
		catch (Exception e)
			return "Invalid PrefixOp";
	}
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

	bool opEquals(R)(const R other) const {
		return this.type == other.type && this.argL == other.argL && this.argR == other.argR;
	}

	string toString() const pure nothrow {
		import std.conv : to;

		try
			return type.to!string ~ '(' ~ argL.toString ~ ", " ~ argR.toString ~ ')';
		catch (Exception e)
			return "Invalid InfixOp";
	}
}
