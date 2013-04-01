/* description: Parses end executes mathematical expressions. */

%{

var myCounter = 0;
function newLabel(x) {
  return String(x)+myCounter++;
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
               "jmpz "+endif+"\n"+
               $s+
               ":"+endif+"\n"; 
        }
    | IF e THEN s ELSE s
        { 
          var lendif = newLabel('endif');
          var lelse  = newLabel('else');
          $$ = $e+
               "jmpz "+lelse+"\n"+
               $s1+
               "jmp "+lendif+"\n"+
               ":"+lelse+"\n"+
               $s2+
               ":"+lendif+"\n"; 
        }
    ;

e
    : ID '=' e
        { $$ = $e+
               "\t"+$ID+"\n"+
               "\t=\n"; 
        }
    | PI '=' e 
        { throw new Error("Can't assign to constant 'π'"); }
    | E '=' e 
        { throw new Error("Can't assign to math constant 'e'"); }
    | e '<=' e
        {$$ = $1+" "+$3+"\t<=\n";}
    | e '>=' e
        {$$ = $1+" "+$3+"\t>=\n";}
    | e '==' e
        {$$ = $1+" "+$3+"\t==\n";}
    | e '+' e
        {$$ = $1+" "+$3+"\t+\n";}
    | NUMBER
        {$$ = "\t"+$NUMBER+"\n";}
    | E
        {$$ = "\t"+Math.E+"\n";}
    | PI
        {$$ = "\t"+Math.PI+"\n";}
    | ID 
        {$$ = "\t"+$ID+"\n";}
    ;

