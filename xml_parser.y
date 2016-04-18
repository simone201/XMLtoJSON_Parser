%{
	import java.io.*;
	import java.util.Stack;
%}

%token NL EQ

%token XML_START XML_CLOSE
%token<sval> XML_VER XML_ENCODING

%token DOCTYPE_START
%token<sval> DOCTYPE_DTD DOCTYPE_EXTID

%token TAG_OPEN TAG_CLOSE TAG_BEGIN_CLOSE TAG_EMPTY_CLOSE

%token<sval> NAME TEXT ATT_VALUE

%type<sval> prolog xml doctype
%type<sval> empty_element start_element end_element element
%type<sval> content chardata attribute

%%

document : prolog element TEXT { System.out.println("\n\n" + $1 + $2 + "\n\n"); }
		 ;

prolog : xml doctype { $$ = $1 + $2; }
	   ;

xml : XML_START XML_VER XML_ENCODING XML_CLOSE { $$ = ""; }
	;

doctype : DOCTYPE_START NAME DOCTYPE_EXTID DOCTYPE_DTD TAG_CLOSE { $$ = ""; }
		;

element : empty_element { $$ = $1; }
		| start_element content end_element { $$ = $1 + "\n\"content\": [" + $2 + "\n]" + $3; }
		;

empty_element : TAG_OPEN NAME attribute TAG_EMPTY_CLOSE 
					{
						if(tags.empty())
							$$ = "\n{\n\"tag\": \"" + $2 + "\"," + $3 + "\n}";
						else
							$$ = "\n{\n\"tag\": \"" + $2 + "\"," + $3 + "\n},";
					}
			  ;

start_element : TAG_OPEN NAME attribute TAG_CLOSE
					{
						tags.push($2);
						$$ = "\n{\n\"tag\": \"" + $2 + "\"," + $3;
					}
			  ;

content : { $$ = ""; }
		| element { $$ = $1; }
		| chardata
			{
				if($1.trim().length() < 1)
					$$ = "";
				else
					$$ = "\n\"" + $1.replaceAll("\n", "").trim() + "\"";
			}
		| chardata element content
			{
				if($1.trim().length() < 1)
					$$ = $2 + $3;
				else
					$$ = "\n\"" + $1.replaceAll("\n", "").trim() + "\"," + $2 + $3;
			}
		;

chardata : TEXT { $$ = replaceSpecial($1.trim()); }
		 ;

end_element : TAG_BEGIN_CLOSE NAME TAG_CLOSE 
				{
					String temp = tags.pop();
					if(tags.empty())
						$$ = "\n}";
					else
						$$ = "\n},";
					tags.push(temp);
					if(tags.peek().equals($2))
						tags.pop();
					else {
						yyerror("Overlapping or wrong closed tags detected");
						return 1;
					}
				}
			;

attribute : { $$ = ""; }
		  | NAME EQ ATT_VALUE attribute { $$ = "\n\"@" + $1 + "\": " + replaceSpecial($3) + "," + $4; }
		  ;

%%

	private Yylex lexer;
	private Stack<String> tags;

	public Parser(Reader r) {
		lexer = new Yylex(r, this);
		tags = new Stack<>();
		//yydebug = true;
	}

	public static void main(String args[]) {
		Parser yyparser;
		
		if (args.length > 0) {
			try {
				yyparser = new Parser(new FileReader(args[0]));
				yyparser.yyparse();
			} catch (Exception e) {
				e.printStackTrace();
			}
		} else
			System.out.println("ERROR: Provide an input file as Parser argument");
	}

	private String replaceSpecial(String input) {

		if(input.contains("&gt;"))
			input = input.replaceAll("&gt;", ">");
			
		if(input.contains("&lt;"))
			input = input.replaceAll("&lt;", "<");
			
		if(input.contains("&apos;"))
			input = input.replaceAll("&apos;", "'");
			
		if(input.contains("&quot;"))
			input = input.replaceAll("&quot;", "\"");
			
		if(input.contains("&amp;"))
			input = input.replaceAll("&amp;", "&");
	
		return input;
	}

	private int yylex() {
		int yyl_return = -1;
		
		try {
			yylval = new ParserVal(0);
			yyl_return = lexer.yylex();
		} catch (IOException e) {
			System.err.println("IO error: " + e);
		}
		
		return yyl_return;
	}

	public void yyerror(String error) {
		System.err.println ("Error: " + error);
	}
