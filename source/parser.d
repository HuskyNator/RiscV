module parser;
import token;
import asm_token;
import asm_;
import std.exception : enforce;

struct Parser {
	Token[] tokens;
	Token t;
	ulong p = 0;

	@disable this();

	static Asm parse(Token[] tokens) {
		return Parser(tokens).parse();
	}

private:
	this(Token[] tokens) {
		this.tokens = tokens;
		enforce(tokens.length > 0, "Parser needs non-empty token list");
		t = tokens[0];
	}

	Asm parse() {
		Asm asm_ = Asm();

		while (p < tokens.length) {
			
		}

		return asm_;
	}

}
