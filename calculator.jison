/* description: Parses end executes mathematical expressions. */

%{

%}

/* operator associations and precedence */

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
          return $$;
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
    ;

e
    : ID '=' e
        { $$ = $e+" "+$ID+" ="; }
    | PI '=' e 
        { throw new Error("Can't assign to constant 'π'"); }
    | E '=' e 
        { throw new Error("Can't assign to math constant 'e'"); }
    | e '<=' e
        {$$ = $1+" "+$3+" <=";}
    | e '>=' e
        {$$ = $1+" "+$3+" >=";}
    | e '==' e
        {$$ = $1+" "+$3+" ==";}
    | e '+' e
        {$$ = $1+" "+$3+" +";}
    | NUMBER
    | E
        {$$ = Math.E;}
    | PI
        {$$ = Math.PI;}
    | ID 
    ;

