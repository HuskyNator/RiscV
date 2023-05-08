module lexer;
import std.ascii;
import std.conv : to;
import std.exception : enforce;
import std.file : readText;
import std.utf : stride;
import token;

struct Lexer {
	string text;
	Token[] tokens;
	ulong p = 0;
	char c;

	@disable this();

	static Token[] lex(string fileName) {
		return Lexer(fileName).lex();
	}

private:
	this(string fileName) {
		this.text = readText(fileName); // Validates utf as well
		enforce(text.length > 0, "Lexer needs non-empty text");
		c = text[0];
	}

	Token[] lex() {
		while (p < text.length) {
			tokens ~= nextToken();
		}
		return tokens;
	}

	void nextChar() {
		assert(p < text.length);
		p += stride(text, p); // skip multi-byte code-points

		if (p >= text.length)
			c = '\0'; // or 0x03 (end of text)
		else
			c = text[p]; // may refer to first code-point of multi-byte utf8
		// Not an issue when comparing to single-byte characters
	}

	bool isSpace(char c) {
		return c == ' ' || c == '\t' || c == '\r';
	}

	void clearSpace() {
		while (isSpace(this.c))
			nextChar();
	}

	bool isSymbolStart(char c) {
		return isAlphaNum(c) || c == '_' || c == '.' || c == '$';
	}

	bool isSymbolChar(char c) {
		return isAlphaNum(c) || c == '_' || c == '$';
	}

	Token nextToken() {
		clearSpace();

		Token cToken(Token.Type type) {
			nextChar();
			return Token(type);
		}

		with (Token.Type) switch (c) {
			// case '\'':
			// 	return charToken();
		case '\"':
			return stringToken();
		case '#':
			return comment();
		case ',':
			return cToken(COMMA);
		case '.':
			return cToken(DOT);
		case ':':
			return cToken(COLON);
		case '\n':
			return cToken(NEWLINE);
		case '(':
			return cToken(OPENBRACKET);
		case ')':
			return cToken(CLOSEBRACKET);
		case '%':
			return cToken(PERCENT);
		case '+':
			return cToken(PLUS);
		case '-':
			return cToken(MINUS);
		case '*':
			return cToken(STAR);
		case '/':
			return cToken(SLASH);
		case '~':
			return cToken(TILDE);
		case '>':
			return tryFollow(['>', '='], [SHIFT_RIGHT, MORE_EQUAL], MORE);
		case '<':
			return tryFollow(['<', '>', '='], [
					SHIFT_LEFT, NOT_EQUAL2, LESS_EQUAL
				], LESS);
		case '|':
			return tryFollow(['|'], [LOGIC_OR], OR);
		case '&':
			return tryFollow(['&'], [LOGIC_AND], AND);
		case '^':
			return cToken(CARET);
		case '!':
			return tryFollow(['='], [NOT_EQUAL], AND);
		case '=':
			return tryFollow(['='], [EQUAL], EQUAL_SIGN);
		default:
			if (isDigit(c))
				return number();
			else
				return symbol();
		}
	}

	Token tryFollow(char[] nexts, Token.Type[] types, Token.Type elseType) {
		assert(nexts.length == types.length);
		nextChar();
		foreach (i, char next; nexts)
			if (c == next)
				return Token(types[i]);
		return Token(elseType);
	}

	Token stringToken() {
		assert(c == '\"');
		nextChar();
		bool delimited = false;
		immutable ulong pOld = p;

		while (delimited || c != '\"') {
			enforce(p < text.length, "Lexer unexpectedly reached EOF while lexing string at position: " ~ p
					.to!string);
			enforce(c != '\n', "Lexer found unexpected \'\\n\' while lexing string at position: " ~ p
					.to!string);
			delimited = c == '\\';
			nextChar();
		}
		nextChar(); // skip "
		return Token(Token.Type.STRING, text[pOld .. p - 1].idup);
	}

	Token comment() {
		assert(c == '#');
		immutable ulong pOld = p;

		nextChar();
		while (c != '\n' && c != '\0')
			nextChar();

		return Token(Token.Type.COMMENT, text[pOld .. p].idup);
	}

	Token comma() {
		assert(c == ',');
		nextChar();
		return Token(Token.Type.COMMA);
	}

	Token dot() {
		assert(c == '.');
		nextChar();
		return Token(Token.Type.DOT);
	}

	Token colon() {
		assert(c == ':');
		nextChar();
		return Token(Token.Type.COLON);
	}

	Token newline() {
		assert(c == '\n');
		nextChar();
		return Token(Token.Type.NEWLINE);
	}

	Token number() {
		assert(isDigit(c));
		immutable ulong pOld = p;
		while (isAlphaNum(c))
			nextChar();
		return Token(Token.Type.Number, text[pOld .. p].idup);
	}

	Token symbol() {
		enforce(isSymbolStart(c), "Lexer found unexpected char \'" ~ c ~ "\' at position: " ~ p
				.to!string);
		immutable ulong pOld = p;
		while (isSymbolChar(c))
			nextChar();
		return Token(Token.Type.SYMBOL, text[pOld .. p].idup);
	}
}
