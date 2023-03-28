module parser;
import asm_;
import asm_token;
import std.conv : to;
import std.exception : enforce;
import token;

struct Parser {
	Token[] tokens;
	ulong p = 0;

	@disable this();

	static Asm parse(Token[] tokens) {
		return Parser(tokens).parse();
	}

private:
	this(Token[] tokens) {
		this.tokens = tokens;
		enforce(tokens.length > 0, "Parser needs non-empty token list");
	}

	Asm parse() {
		Asm asm_ = Asm();

		while (p < tokens.length)
			asm_.tokens ~= parseAsmToken();

		return asm_;
	}

	bool hasColonNext() {
		return p + 1 < tokens.length && tokens[p + 1].type == Token.Type.COLON;
	}

	AsmToken parseAsmToken() {
	parseAsmToken_start:
		Token next = tokens[p];
		with (Token.Type) final switch (next.type) {
		case SYMBOL:
			if (hasColonNext)
				return label();
			return instruction();
		case DOT:
			// if(hasColonNext) return label();
			return directive();
		case COMMENT:
			return comment();
		case COMMA:
			assert(0, "Parser found unexpected comma: " ~ tokens[0 .. p].to!string);
		case COLON:
			assert(0, "Parser found unexpected colon: " ~ tokens[0 .. p].to!string);
		case NEWLINE:
			goto parseAsmToken_start;
		}
	}

	AsmToken comment() {
		p += 1;
		return AsmToken(AsmToken.Type.COMMENT, tokens[p - 1].content.idup);
	}

	AsmToken label() {
		p += 2;
		return AsmToken(AsmToken.Type.LABEL, tokens[p - 2].content.idup);
	}

	AsmToken instruction() {
		return AsmToken(AsmToken.Type.COMMENT, tokens[p - 1].content.idup);
	}

	AsmToken directive() {
return AsmToken(AsmToken.Type.COMMENT, tokens[p - 1].content.idup);
	}
}
