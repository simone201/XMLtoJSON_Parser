%%

%byaccj

%{
	private Parser yyparser;
	private String val;
	private int prevState = -1;

	public Yylex(java.io.Reader r, Parser yyparser) {
		this(r);
		this.yyparser = yyparser;
	}
%}

%x IN_TAG IN_CONTENT IN_DOCTYPE IN_TAG_END

NL  = \r\n|\r|\n
EQ = "="

NAME = [a-zA-Z:_] [a-zA-Z0-9:_\-.]*
TEXT = [^<&("]]>")]*

XML_START = "<?xml"
XML_CLOSE = "?>"
XML_VERNUM = "1.0" | "1.1"
XML_ENCNAME = [A-Za-z] ([A-Za-z0-9._] | "-")*
XML_VER = "version" {EQ} ("'" {XML_VERNUM} "'" | "\"" {XML_VERNUM} "\"")
XML_ENCODING = "encoding" {EQ} ("\"" {XML_ENCNAME} "\"" | "'" {XML_ENCNAME} "'" )

DOCTYPE_START = "<!DOCTYPE"
DOCTYPE_EXTID = "SYSTEM" | "PUBLIC"
DOCTYPE_DTD = "\"" {NAME} "\""

TAG_OPEN = "<"
TAG_CLOSE = ">"
TAG_BEGIN_CLOSE = "</"
TAG_EMPTY_CLOSE = "/>"

ATT_VALUE = "\"" ([^<&\"] | {REFERENCE})* "\"" | "'" ([^<&'] | {REFERENCE})* "'"

ENTITY_REF = "&" {NAME} ";"
CHAR_REF = "%" {NAME} ";"
REFERENCE = {ENTITY_REF} | {CHAR_REF}

%%

{ENTITY_REF} { }
{CHAR_REF} { }
{REFERENCE} { }

{XML_START} { return Parser.XML_START; }
		
{XML_CLOSE} { return Parser.XML_CLOSE; }
		
{XML_VERNUM} { }
{XML_ENCNAME} { }

{XML_VER} { yyparser.yylval = new ParserVal(yytext());
			return Parser.XML_VER; }

{XML_ENCODING} { yyparser.yylval = new ParserVal(yytext());
				 return Parser.XML_ENCODING; }		

{DOCTYPE_START} { yybegin(IN_DOCTYPE);
				  return Parser.DOCTYPE_START; }

<IN_DOCTYPE> {
	
	{DOCTYPE_EXTID} { yyparser.yylval = new ParserVal(yytext());
					  return Parser.DOCTYPE_EXTID; }

	{DOCTYPE_DTD} { yyparser.yylval = new ParserVal(yytext());
					return Parser.DOCTYPE_DTD; }

}

<YYINITIAL,IN_CONTENT> {

	{TAG_OPEN} { if(yystate() == IN_CONTENT) prevState = yystate();
				 else prevState = -1;
				 yybegin(IN_TAG);
				 return Parser.TAG_OPEN; }

}

<IN_TAG> {

	{EQ} { return Parser.EQ; }

	{ATT_VALUE} { yyparser.yylval = new ParserVal(yytext());
				  return Parser.ATT_VALUE; }

	{TAG_EMPTY_CLOSE} { if(prevState == IN_CONTENT)
							yybegin(IN_CONTENT);
						else
							yybegin(YYINITIAL);
						return Parser.TAG_EMPTY_CLOSE; }

}

<IN_CONTENT> {

	{TEXT} { yyparser.yylval = new ParserVal(yytext());
			 return Parser.TEXT; }

	{TAG_BEGIN_CLOSE} { yybegin(IN_TAG_END);
						return Parser.TAG_BEGIN_CLOSE; }

}

<IN_TAG,IN_TAG_END,IN_DOCTYPE> {

	{NAME} { yyparser.yylval = new ParserVal(yytext());
			 return Parser.NAME; }

	{TAG_CLOSE} { if(yystate() == IN_TAG
					|| (yystate() == IN_TAG_END && prevState == IN_CONTENT))
					  yybegin(IN_CONTENT);
				  else
					  yybegin(YYINITIAL);
				  return Parser.TAG_CLOSE; }

}

/* newline, whitespace & special */
<YYINITIAL,IN_CONTENT,IN_TAG,IN_DOCTYPE,IN_TAG_END> {

	{NL} { }

	[ \t]+ { }

}

\b     { System.err.println("Sorry, backspace doesn't work"); }

/* error fallback */
[^]    { System.err.println("Error: unexpected character '" + yytext() + "'"); return -1; }
