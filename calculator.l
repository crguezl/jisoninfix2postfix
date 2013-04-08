/* lexical grammar */
%{
var reserved_words ={ DEF: 'DEF',
                      IF: 'IF', THEN: 'THEN', ELSE: 'ELSE', 
                      PI: 'PI', E : 'E'}

function idORrw(x) {
  return (x.toUpperCase() in reserved_words)? x.toUpperCase() : 'ID'
}

%}
%%

\s+|\#.*                         { /* skip whitespace and comments */ }
\b\d+("."\d*)?([eE][-+]?\d+)?\b  return 'NUMBER'
\b[A-Za-z_]\w*\b                 return idORrw(yytext)
[<>=!][=]                         {
                                   return yytext; 
/* exact string patterns must be placed in quotes
   http://zaach.github.com/jison/docs/#lexical-analysis
*/
                                 }
[-*+/^!%=(),;<>{}]                return yytext;
<<EOF>>                          return 'EOF'
.                                return 'INVALID'


