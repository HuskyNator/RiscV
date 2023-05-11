module token;

struct Token {
	enum Type {
		SYMBOL,
		NUMBER,
		COMMENT,
		DOT, // .
		COMMA, // ,
		COLON, // :
		NEWLINE, // \n
		STRING,
		OPENBRACKET, // (
		CLOSEBRACKET, // )
		EQUAL_SIGN, // =
		TILDE, // ~
		STAR, // *
		SLASH, // /
		PERCENT, // %
		SHIFT_RIGHT, // >>
		SHIFT_LEFT, // <<
		OR, // |
		AND, // &
		CARET, // ^
		EXCLAMATION, // !
		PLUS, // +
		MINUS, // -
		EQUAL, // ==
		NOT_EQUAL2, // <>
		NOT_EQUAL, // !=
		LESS, // <
		MORE, // >
		MORE_EQUAL, // >=
		LESS_EQUAL, // <=
		LOGIC_AND, // &&
		LOGIC_OR, // ||
	}

	this(Type type, string content = null) {
		this.type = type;
		this.content = content;
	}

	Type type;
	string content;

	string toString() const @safe pure nothrow {
		import std.conv : to;

		try
			return type.to!string ~ "(" ~ content ~ ")";
		catch (Exception e)
			return "Invalid token";
	}
}
