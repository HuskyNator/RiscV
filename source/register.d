module register;
import std.conv : to;

// Struct to serve as enum
struct Reg {
	ubyte val;
	alias val this;

	mixin(_ctReg()); // Enum members

	this(string name) {
		static foreach (reg; __traits(allMembers, Reg)) {
			static if (reg != "val" && is(typeof("Reg." ~ reg) == ubyte))
				if (name == reg) {
					this.val = mixin("Reg." ~ reg);
					return;
				}
		}
		assert(0, "Register name invalid: " ~ name);
	}

	// Aliases
	alias zero = x0;
	alias ra = x1;
	alias sp = x2;
	alias gp = x3;
	alias tp = x4;
	static foreach (i; 0 .. 3) // t0..t3 = x5..x7
		mixin("alias t" ~ i.to!string ~ "= x" ~ (i + 5).to!string ~ ';');
	alias s0 = x8;
	alias fp = x8;
	alias s1 = x9;
	static foreach (i; 0 .. 8) // a0..a7 = x10..x17
		mixin("alias a" ~ i.to!string ~ "= x" ~ (i + 10).to!string ~ ';');
	static foreach (i; 2 .. 12) // s2..s11 = x18..x27
		mixin("alias s" ~ i.to!string ~ "= x" ~ (i + 16).to!string ~ ';');
	static foreach (i; 3 .. 7) // t3..t7 = x28..x31
		mixin("alias t" ~ i.to!string ~ "= x" ~ (i + 25).to!string ~ ';');
}

// Generates x0..x31 register enum
private string _ctReg() {
	string s = "enum:ubyte {";
	foreach (i; 0 .. 32) {
		s ~= "x" ~ i.to!string ~ ',';
	}
	return s ~ '}';
}
