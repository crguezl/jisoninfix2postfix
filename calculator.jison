/* description: Translates infix expressions to postfix. */

%{

var myCounter = 0;
function newLabel(x) {
  return String(x)+myCounter++;
}

function translateIf(e, s) {
  var endif = newLabel('endif');
  return e+unary("jmpz "+endif)+s+label(endif); 
}

function translateIfElse(e, s1, s2) {
  var lendif = newLabel('endif');
  var lelse  = newLabel('else');
  return (e+
       unary("jmpz "+lelse)+
       s1+
       unary("jmp "+lendif)+
       label(lelse)+
       s2+
       label(lendif)); 
}

function binary(x,y,op) {
  return x+" "+y+"\t"+op+"\n";
}

function unary(x) {
  return "\t"+x+"\n";
}

function label(x) {
  return ":"+x+"\n"; 
}

%}

/* operator associations and precedence */

%left THEN
%right ELSE
%right '='
%left '<' '<=' '>' '>=' '=='
%left '+' '-'
%left '*' '/'
%left '^'
%left '!'
%right '%'
%left UMINUS

%start prog

%% /* language grammar */
prog
    : expressions EOF
        { 
          $$ = $1; 
          console.log($$);
          return $$.join("");
        }
    ;

expressions
    : s  
        { $$ = $1? [ $1 ] : []; }
    | expressions ';' s
        { $$ = $1;
          if ($3) $$.push($3); 
          console.log($$);
        }
    ;

s
    : /* empty */
    | e
    | IF e THEN s
        { $$ = translateIf($e, $s); }
    | IF e THEN s ELSE s
        { $$ = translateIfElse($e, $s1, $s2); }
    ;

e
    : ID '=' e
        {$$ = binary($3,unary($1), "=");}
    | PI '=' e 
        { throw new Error("Can't assign to constant 'π'"); }
    | E '=' e 
        { throw new Error("Can't assign to math constant 'e'"); }
    | e '<=' e
        {$$ = binary($1,$3, "<=");}
    | e '>=' e
        {$$ = binary($1,$3, ">=");}
    | e '<' e
        {$$ = binary($1,$3, "<");}
    | e '>' e
        {$$ = binary($1,$3, ">");}
    | e '==' e
        {$$ = binary($1,$3, "==");}
    | e '+' e
        {$$ = binary($1,$3, "+");}
    | e '*' e
        {$$ = binary($1,$3, "*");}
    | e '/' e
        {$$ = binary($1,$3, "/");}
    | '(' e ')'
        {$$ = $2;}
    | NUMBER
        {$$ = unary($NUMBER);}
    | E
        {$$ = unary(Math.E);}
    | PI
        {$$ = unary(Math.PI);}
    | ID 
        {$$ = unary($ID);}
    ;

