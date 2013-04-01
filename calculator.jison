/* description: Parses end executes mathematical expressions. */

%{

var myCounter = 0;
function newLabel(x) {
  return String(x)+myCounter++;
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
        { 
          var endif = newLabel('endif');
          $$ = $e+
               unary("jmpz "+endif)+
               $s+
               label(endif); 
        }
    | IF e THEN s ELSE s
        { 
          var lendif = newLabel('endif');
          var lelse  = newLabel('else');
          $$ = $e+
               unary("jmpz "+lelse)+
               $s1+
               unary("jmp "+lendif)+
               label(lelse)+
               $s2+
               label(lendif); 
        }
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

