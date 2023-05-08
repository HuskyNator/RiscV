module app;
import lexer;
import register;
import std.array : split;
import std.exception : enforce;
import std.file;
import std.stdio;
import std.string : strip;
import token;
import parser;
import asm_;

void main(string[] args) {
	enforce(args.length == 2, "Need 1 file as argument");
	string fileName = args[1];

	Token[] tokens = Lexer.lex(fileName);
	writeln(tokens);
	Asm program = Parser.parse(tokens);
	writeln(program);
}
