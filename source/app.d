module app;
import lexer;
import register;
import std.array : split;
import std.exception : enforce;
import std.file;
import std.path : isValidFilename;
import std.stdio;
import std.string : strip;
import token;
import parser;
import asm_;

void main(string[] args) {
	enforce(args.length == 2, "Need 1 file or string as argument");
	string fileNameOrString = args[1];

	Token[] tokens;
	if (isValidFilename(fileNameOrString) && isFile(fileNameOrString))
		tokens = Lexer.lexFile(fileNameOrString);
	else {
		writeln("Argument not a file, parsing as string input");
		tokens = Lexer.lex(fileNameOrString);
	}
	writeln(tokens);
	Asm program = Parser.parse(tokens);
	writeln(program);
}
