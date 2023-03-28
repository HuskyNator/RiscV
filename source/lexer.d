module lexer;
import std.ascii;
import std.conv : to;
import std.exception : enforce;
import std.file : readText;
import std.uni : graphemeStride;
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
		p += graphemeStride(text, p); // skip multi-byte code-points

		if (p >= text.length)
			c = '\0'; // or 0x03 (end of text)
		else
			c = text[p]; // may refer to first code-point of multi-byte utf8
		// Not an issue when comparing to single-byte characters
	}

	bool isSpace(char c) {
		return c == ' ' || c == '\t';
	}

	void clearSpace() {
		while (isSpace(this.c))
			nextChar();
	}

	bool isSymbolChar(char c) {
		return isAlphaNum(c) || c == '_' || c == '.' || c == '$';
	}

	Token nextToken() {
		clearSpace();

		switch (c) {
			// case '\'':
			// 	return charToken();
			case '\"':
				return stringToken();
			case '#':
				return comment();
			case ',':
				return comma();
			case '.':
				return dot();
			case ':':
				return colon();
			case '\n':
				return newline();
			default:
				return symbol();
		}
	}

	// Token charToken() {
	// }

	Token stringToken() {
		assert(c == '\"');
		nextChar();
		bool delimited = false;
		immutable ulong pOld = p;

		while (delimited || c != '\"') {
			enforce(p < text.length, "Lexer unexpectedly reached EOF while lexing string at position: " ~ p.to!string);
			enforce(c != '\n', "Lexer found unexpected \'\\n\' while lexing string at position: " ~ p.to!string);
			delimited = c == '\\';
			nextChar();
		}
		nextChar(); // skip "
		return Token(Token.Type.SYMBOL, text[pOld .. p - 1].idup);
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

	Token symbol() {
		enforce(isSymbolChar(c), "Lexer found unexpected char \'" ~ c ~ "\' at position: " ~ p.to!string);
		immutable ulong pOld = p;
		while (isSymbolChar(c))
			nextChar();
		return Token(Token.Type.SYMBOL, text[pOld .. p].idup);
	}
}
