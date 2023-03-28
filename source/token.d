module token;

struct Token {
	enum Type {
		SYMBOL,
		INSTRUCTION,
		COMMENT,
		DOT,
		COMMA,
		COLON,
		NEWLINE
	}

	this(Type type, string content = null) {
		this.type = type;
		this.content = content;
	}

	Type type;
	string content;
}
