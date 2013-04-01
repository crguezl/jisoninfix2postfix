/* lexical grammar */
%{
var reserved_words ={ IF: 'IF', THEN: 'THEN', ELSE: 'ELSE', 
                      PI: 'PI', E : 'E'}

function idORrw(x) {
  return (x.toUpperCase() in reserved_words)? x.toUpperCase() : 'ID'
}

%}
%%

\s+|\#.*                         /* skip whitespace and comments */
\b\d+("."\d*)?([eE][-+]?\d+)?\b  return 'NUMBER'
\b[A-Za-z_]\w*\b                 return idORrw(yytext)
[<>=][=]                         return yytext;
[-*/+^!%=();<>]                  return yytext;
<<EOF>>                          return 'EOF'
.                                return 'INVALID'


