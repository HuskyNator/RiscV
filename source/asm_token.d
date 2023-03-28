module asm_token;
import std.array : split;
import std.conv : to;

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
}

alias Comment = string;
alias Label = string;
// TODO: move to data file, include instruction format etc.
struct Instruction {
	mixin(_ctInstrEnum!true);
	static Format[Type] formatMap;
	static this() {
		foreach (line; csv_instrs.split('\n')) {
			string[] instr = line.split(',');
			assert(instr.length == 2);
			Type t = instr[0].to!Type;
			Format f = instr[1].to!Format;
			formatMap[t] = f;
		}
		// csv_instrs = null; // dealocate
	}

	enum Format {
		R,
		I,
		S,
		B,
		U,
		J,
		P //P=Pseudo
	}

	Type type;
	Format format;
}

private string _ctInstrEnum(bool includePseudo)() {
	private immutable string csv_instrs = import("instructions.csv");
	string enum_ = "enum Type{";
	foreach (line; csv_instrs.split('\n')) {
		if (line[0] != '#') {
			immutable string[] instr = line.split(',');
			assert(instr.length == 2);
			if (includePseudo || instr[1] != "P")
				enum_ ~= instr[0] ~ `,`;
		}
	}
	return enum_ ~ '}';
}

struct Directive {

}
