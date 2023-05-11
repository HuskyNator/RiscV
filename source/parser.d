module parser;
import asm_;
import asm_token;
import core.exception : AssertError;
import num_promise;
import register;
import std.conv : to;
import std.exception : assertNotThrown, enforce;
import std.string : toUpper;
import std.traits : isIntegral;
import token;

struct Parser {
	AsmToken[] asmTokens;
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
		while (p < tokens.length)
			parseAsmToken();
		return Asm(asmTokens);
	}

	bool hasColonNext() {
		return p + 1 < tokens.length && tokens[p + 1].type == Token.Type.COLON;
	}

	void parseAsmToken() {
		tryParseLabel();
		tryParseDirectiveOrInstruction();
		parseToken!(Token.Type.COMMENT, false)();
		parseToken!(Token.Type.NEWLINE)();

		// with (Token.Type) final switch (next.type) {
		// case SYMBOL:
		// 	if (hasColonNext)
		// 		label();
		// 	instruction();
		// case DOT:
		// 	// if(hasColonNext) return label();
		// 	return parseDirective;
		// case COMMENT:
		// 	return comment();
		// case COMMA:
		// 	assert(0, "Parser found unexpected comma: " ~ tokens[0 .. p].to!string);
		// case COLON:
		// 	assert(0, "Parser found unexpected colon: " ~ tokens[0 .. p].to!string);
		// case NEWLINE:
		// 	goto parseAsmToken_start;
		// }
	}

	ulong remaining() {
		return tokens.length - p;
	}

	string failS(ulong following) {
		long start = p - 5;
		start = start < 0 ? 0 : start;
		return "\nParser failed at end of token context:\n" ~ tokens[start .. p + following].to!string;
	}

	void tryParseLabel() {
		with (AsmToken.Type) with (Token.Type)
			if (remaining >= 3 && tokens[p].type == DOT && tokens[p + 1].type == SYMBOL && tokens[p + 2].type == COLON) {
				asmTokens ~= AsmToken(LABEL, tokens[p + 1].content.idup);
				p += 3;
			} else if (remaining >= 2 && tokens[p].type == SYMBOL && tokens[p + 1].type == COLON) {
				asmTokens ~= AsmToken(LABEL, tokens[p].content.idup);
				p += 2;
			}
	}

	void tryParseDirectiveOrInstruction() {
		with (Token.Type) {
			if (remaining == 0)
				return;
			if (tokens[p].type == DOT)
				parseDirective();
			else if (tokens[p].type == SYMBOL)
				parseInstruction();
		}
	}

	Reg parseReg() {
		string regStr = parseToken!(Token.Type.SYMBOL);
		Reg reg;
		try
			reg = Reg(regStr);
		catch (RegNameException e)
			throw new RegNameException(e.msg ~ failS(0));
		return reg;
	}

	string parseToken(Token.Type type, bool force = true)() {
		bool hasRemaining = remaining >= 1;
		bool isType = tokens[p].type == type;
		if (!force && (!hasRemaining || !isType))
			return null;
		enforce(hasRemaining, "Parser expected " ~ type.stringof ~ " but reached end: " ~ failS(0));
		enforce(isType, "Parser expected " ~ type.stringof ~ " but got: " ~ failS(1));
		p += 1;
		return tokens[p - 1].content.idup;
	}

	Instruction.Arg parseArgs(Instruction.ArgFormat argF) {
		Instruction.Arg arg;
		with (Instruction.ArgFormat) with (Token.Type) final switch (argF) {
			case RRR:
				arg.regs = parseList!Reg(&parseReg, 3u);
				break;
			case RRI:
				arg.regs = parseList!Reg(&parseReg, 2u);
				arg.numPromises = [parseNumber()];
				break;
			case RIR:
				Reg reg1 = parseReg();
				parseToken!COMMA();
				NumPromise imm = parseNumber();
				parseToken!OPENBRACKET();
				Reg reg2 = parseReg();
				parseToken!CLOSEBRACKET();
				arg.regs = [reg1, reg2];
				arg.numPromises = [imm];
				break;
			case RI:
				arg.regs = [parseReg()];
				parseToken!COMMA();
				arg.numPromises = [parseNumber()];
				break;
			case NONE:
				break;
			case FENCE:
				arg.symbols = parseList!string(&parseToken!SYMBOL);
				break;
			case CSRR:
				arg.regs = [parseReg()];
				parseToken!COMMA();
				goto case CSR;
			case CSR:
				string csr = parseToken!SYMBOL();
				parseToken!COMMA();
				arg.regs ~= parseReg();
				arg.symbols = [csr];
				break;
			case CSRRI:
				arg.regs = [parseReg()];
				parseToken!COMMA();
				goto case CSRI;
			case CSRI:
				arg.symbols = [parseToken!SYMBOL()];
				parseToken!COMMA();
				arg.numPromises = [parseNumber()];
				break;
			case RR:
				arg.regs = parseList!Reg(&parseReg, 2);
				break;
			case RS:
				arg.regs = [parseReg()];
				arg.symbols = [parseToken!SYMBOL()];
				break;
			case ORS:
				enforce(remaining >= 1, "Parser expected ORS arg token(s) but reached end: " ~ failS(0));
				if (tokens[p].type == SYMBOL && remaining >= 2 && tokens[p + 1].type == COMMA) {
					arg.regs = [parseReg()];
					parseToken!COMMA();
				}
				arg.symbols = [parseToken!SYMBOL()];
				break;
			case I:
				arg.numPromises = [parseNumber()];
				break;
			case R:
				arg.regs = [parseReg()];
				break;
			case S:
				arg.symbols = [parseToken!SYMBOL()];
		}
		return arg;
	}

	AsmToken parseInstruction() {
		with (Instruction) with (Format) {
			string typeStr = parseToken!(Token.Type.SYMBOL)();
			Type type = typeStr.toUpper.to!Type;
			Format format = formatMap[type];
			Instruction instr = Instruction(type, format);
			instr.args = parseArgs(format.argF);
			return AsmToken(instr);
		}
	}

	NumPromise parseNumber() {
		if (remaining == 0)
			return new NumPromise(0); // default 0

		ulong pOld = p;
		with (Token.Type)
			while (remaining > 0) { // parse until comma or newline
				Token.Type t = tokens[p].type;
				if (t == COMMA || t == NEWLINE)
					break;
				p += 1;
			}
		return parseNumber(pOld, p);

		// // enforce(remaining >= 1, "Parser expected number but reached end: " ~ failS(0)); // TODO: assume 0
		// with (Token.Type) switch (tokens[p].type) {
		// case PERCENT:
		// 	return parseModifier();
		// case SYMBOL: //TODO
		// case MINUS, COMPLEMENT:
		// 	return parsePrefix();
		// }
	}

	struct InfixToken {
		union {
			NumPromise promise;
			InfixOp.Type operator;
		}

		bool isOperator;
		this(InfixOp.Type t) {
			isOperator = true;
			operator = t;
		}

		this(NumPromise n) {
			isOperator = false;
			promise = n;
		}

		string toString() const pure {
			if (isOperator)
				return operator.to!string;
			else
				return promise.toString;
		}
	}

	/// Parses a number from a range of tokens.
	/// Params:
	///   start = Where to start parsing.
	///   end = Where to stop parsing (exclusive).
	/// Returns: The parsed number.
	NumPromise parseNumber(ulong start, ulong end) {
		InfixToken[] list;
		ulong current = start;

		// Read infix expression
		while (current < end) {
			if (list.length % 2 == 1) {
				list ~= InfixToken(tokenToOp(tokens[current].type));
				current += 1;
			} else
				list ~= InfixToken(parseNumberSimple(current, end, &current));
		}

		enforce(list.length % 2 == 1, "Expected odd number of tokens in infix expression: " ~ failS(0));
		return parseInfixListToNum(list);
	}

	unittest {
		import lexer;

		Token[] tokens = Lexer.lex("1 + 2 * 3 + ( 5 * 7 & 2 ) * 4");
		Parser p = Parser(tokens);
		NumPromise n = p.parseNumber(0, tokens.length);

		// Order of evaluation ((1 + (2 * 3)) + ( (5 * 7) & 2 ) * 4)
		alias NP = NumPromise;
		alias IO = InfixOp;
		with (InfixOp.Type) {
			NumPromise correct = new NP(IO(ADD, new NP(IO(ADD, new NP(1), new NP(IO(MULT, new NP(2), new NP(3))))),
					new NP(IO(MULT, new NP(IO(AND, new NP(IO(MULT, new NP(5), new NP(7))), new NP(2))), new NP(4)))));
			assert(n == correct);
		}
	}

	/// Recursively parses a list of infix tokens to a number.
	/// Params:
	///   list = list of infix tokens.
	/// Returns: The parsed number.
	NumPromise parseInfixListToNum(InfixToken[] list) {
		assert(list.length != 0);
		if (list.length == 1) {
			assert(!list[0].isOperator);
			return list[0].promise;
		}

		InfixOp.Type max = InfixOp.Type.min;
		ulong leftOp = 0;
		for (ulong i = 1; i < list.length; i += 2) {
			assert(list[i].isOperator);
			InfixOp.Type op = list[i].operator;
			if (op >= max) { // Left operation first: Right most operator outside.
				max = op;
				leftOp = i;
			} else if (op == max && leftOp == 0)
				leftOp = i;
		}
		assert(leftOp != 0, "Could not find operator in infix list: " ~ list.to!string ~ failS(0));
		NumPromise left = parseInfixListToNum(list[0 .. leftOp]);
		NumPromise right = parseInfixListToNum(list[leftOp + 1 .. $]);
		return new NumPromise(InfixOp(max, left, right));
	}

	InfixOp.Type tokenToOp(Token.Type t) {
		with (Token.Type) {
			if (t >= STAR && t <= LOGIC_OR)
				return cast(InfixOp.Type)(t - STAR);
			assert(0, "Could not parse as infix operator: " ~ t.to!string ~ failS(0));
		}
	}

	/// Parses the first number in a range of tokens.
	/// Params:
	///   start = Where to start parsing.
	///   end = Where to stop parsing (exclusive).
	///   simpleEnd = End of parsed number (exclusive).
	/// Returns: The first parsed number.
	NumPromise parseNumberSimple(ulong start, ulong end, ulong* simpleEnd) {
		Token.Type t = tokens[start].type;
		with (Token.Type) with (InfixOp.Type) with (PrefixOp.Type) switch (t) {
			case MINUS, TILDE:
				enforce(start + 1 < end);
				NumPromise n = parseNumberSimple(start + 1, end, simpleEnd);
				PrefixOp po = PrefixOp(t == MINUS ? NEGATE : COMPLEMENT, n);
				return new NumPromise(po);
			case OPENBRACKET:
				ulong close = start;
				while (close < end) {
					if (tokens[close].type == CLOSEBRACKET) {
						NumPromise np = parseNumber(start + 1, close);
						*simpleEnd = close + 1;
						return np;
					}
					close += 1;
				}
				assert(0, "Could not find closing bracket ')': " ~ failS(0));
			case NUMBER:
				int n = to!int(tokens[start].content);
				*simpleEnd = start + 1;
				return new NumPromise(n);
			case PERCENT:
				// TODO modifier
				assert(0, "TODO");
			case SYMBOL:
				// TODO label
				assert(0, "TODO");
			default:
				assert(0, "Could not parse Number: " ~ t.to!string ~ failS(0));
		}
	}

	T[] parseList(T)(T delegate() func, ulong number) {
		T[] list = parseList!T(func);
		enforce(list.length == number, "Parser expected list of length " ~ number.to!string
				~ " but got: " ~ list.length.to!string ~ failS(remaining > 0 ? 1 : 0));
		return list;
	}

	T[] parseList(T)(T delegate() func) {
		T[] list = [func()];
		while (remaining >= 1 && tokens[p].type == Token.Type.COMMA) {
			p += 1;
			list ~= func();
		}
		return list;
	}

	AsmToken parseDirective() {
		with (Token.Type) {
			assert(tokens[p].type == DOT);
			enforce(remaining >= 2,
				"Parser expected directive of 2 tokens but got: " ~ remaining.to!string ~ failS(remaining));
			enforce(tokens[p + 1].type == SYMBOL,
				"Parser expected directive symbol but got: " ~ tokens[p + 1].type.stringof ~ failS(2));
			p += 2;

			with (Directive.Type) {
				Directive.Type dType = tokens[p - 1].content.toUpper.to!(Directive.Type);
				Directive directive = Directive(dType);
				final switch (dType) {
					case ALIGN:
					case BALIGN:
					case ZERO:
						// number
						directive.number = parseNumber();
						break;
					case GLOBAL:
					case OPTION:
						// symbol
						enforce(remaining >= 1, "Parser expected symbol but reached end." ~ failS(0));
						directive.symbol = tokens[p].content.idup;
						p += 1;
						break;
					case BYTE:
					case HALF:
					case WORD:
						// values/expressions
						directive.numbers = parseList!NumPromise(&parseNumber);
						break;
					case ASCII:
					case ASCIZ:
					case STRING:
						// strings
						directive.strings = parseList!string(&parseToken!(Token.Type.STRING, true));
						break;
					case SECTION:
						enforce(remaining >= 2, "Parser expected dot and symbol but reached end." ~ failS(remaining));
						enforce(tokens[p].type == DOT && tokens[p + 1].type == SYMBOL,
							"Parser expected dot and symbol but got: " ~ tokens[p].type.stringof
							~ '&' ~ tokens[p + 1].type.stringof ~ failS(2));
						directive.symbol = tokens[p + 1].content.idup;
						p += 2;
						break;
					case BSS:
					case DATA:
					case TEXT:
						// nothing?
						break;
				}
				return AsmToken(directive);
			}
		}
	}
}
