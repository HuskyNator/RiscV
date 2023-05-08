module asm_token;
import std.string : splitLines;
import std.array : split;
import std.conv : to;
import register;

struct AsmToken {
	enum Type {
		LABEL,
		DIRECTIVE,
		INSTRUCTION,
		COMMENT
	}

	Type type;

	union {
		Label label;
		Directive directive;
		Instruction instruction;
		Comment comment;
	}

	this(Type type, string content) {
		this.type = type;
		this.label = content;
		// this.comment equivalent
	}

	this(Instruction instr) {
		this.type = Type.INSTRUCTION;
		this.instruction = instr;
	}

	this(Directive directive) {
		this.type = Type.DIRECTIVE;
		this.directive = directive;
	}
}

alias Comment = string;
alias Label = string;
struct Instruction {
	mixin(_ctInstrEnum!true);
	// pragma(msg, _ctInstrEnum!true);
	private static string _ctInstrEnum(bool includePseudo)() {
		immutable string csv_instrs = import("instructions.csv");
		string enum_ = "enum Type {";
		string formatMap = "static Format[] formatMap = [";
		foreach (line; csv_instrs.splitLines()) {
			if (line[0] == '#')
				continue;
			string[] instr = line.split(',');
			assert(instr.length == 3, "Expected 3 csv entries but got: " ~ instr.to!string);
			if (!includePseudo && instr[1] == "P")
				continue;
			enum_ ~= instr[0] ~ `,`;

			string asmF = "AsmFormat." ~ instr[1];
			string argF = "ArgFormat." ~ instr[2];
			formatMap ~= "Format(" ~ asmF ~ ',' ~ argF ~ "),";

		}
		return enum_ ~ "}" ~ formatMap[0 .. $ - 1] ~ "];";
	}

	struct Format {
		AsmFormat asmF;
		ArgFormat argF;
	}

	enum AsmFormat {
		R,
		I,
		S,
		B,
		U,
		J,
		P // Pseudo (not a format...)
	}

	enum ArgFormat {
		RRR, // r,r,r
		RRI, // r,r,i
		RIR, // r,i(r)
		RI, // r,i
		NONE, // _
		FENCE, // pred,succ?
		CSRR, // r,csr,r
		CSRRI, // r,csr,i
		// pseudo
		RR, // r,r
		RS, // r,symbol
		ORS, // (r,)symbol (for call)
		I, // immediate
		R, // register
		S, // symbol
		CSR, // csr,r
		CSRI, // csr,i
	}

	struct Arg {
		Reg[] regs;
		NumPromise[] numPromises;
		string[] symbols;
	}

	Type type;
	Format format;
	Arg args;

}

// union {
// 	RArg rArg;
// 	IArg iArg;
// 	SArg sArg;
// 	BArg bArg;
// 	UArg uArg;
// 	JArg jArg;
// 	PArg pArg; // Pseudo
// }

// struct RArg {
// 	Reg rd, rs1, rs2;
// } // RRR

// struct IArg {
// 	Reg rd, rs1;
// 	short imm;
// } // RRI

// struct SArg {
// 	Reg rs1, rs2;
// 	short imm;
// } // RRI

// struct BArg {
// 	Reg rs1, rs2;
// 	short imm;
// } // RRI

// struct UArg {
// 	Reg rd;
// 	int imm;
// } // RI

// struct JArg {
// 	Reg rd;
// 	int imm;
// } // RI

/// Selection of useful Directives
/// Taken from // Selection taken from https://sourceware.org/binutils/docs/as/Pseudo-Ops.html
/// and https://sourceware.org/binutils/docs/as/RISC_002dV_002dDirectives.html
struct Directive {
	enum Type {
		ALIGN, // number
		BALIGN, // number
		GLOBAL, // symbol
		OPTION, // symbol?

		BYTE, // values/expressions
		HALF,
		WORD,
		ASCII, // strings
		ASCIZ,
		STRING,
		ZERO, // number

		SECTION, // .symbol
		BSS, // nothing
		DATA,
		TEXT,
	}

	Type type;
	union {
		long number;
		long[] numbers;
		string symbol;
		string[] strings;
	}

	// arguments
}
