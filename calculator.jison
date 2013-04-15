/* description: 
   Translates infix expressions to postfix. 
   Implements functions and function calls
*/

%{

var symbolTables = [{ name: '', father: null }];
var scope = 0; 
var symbolTable = symbolTables[scope];

function getScope() {
  return scope;
}

function getFormerScope() {
   scope--;
   symbolTable = symbolTables[scope];
}

function makeNewScope(id) {
   scope++;
   symbolTable[id].symbolTable = symbolTables[scope] =  { name: id, father: symbolTable };
   symbolTable = symbolTables[scope];
   return symbolTable;
}

function findSymbol(x) {
  var f;
  var s = scope;
  do {
    f = symbolTables[s][x];
    s--;
  } while (s >= 0 && !f);
  s++;
  return [f, s];
}

var myCounter = 0;
function newLabel(x) {
  return String(x)+myCounter++;
}

function translateIf(e, s) {
  var endif = newLabel('endif');
  return e+unary("jmpz "+endif, 'jump')+s+label(endif, 'jump'); 
}

function translateIfElse(e, s1, s2) {
  var lendif = newLabel('endif');
  var lelse  = newLabel('else');
  return (e+
       unary("jmpz "+lelse,'jump')+
       s1+
       unary("jmp "+lendif,'jump')+
       label(lelse, 'jump')+
       s2+
       label(lendif, 'jump')); 
}

function binary(x,y,op) {
  return x+" "+y+"\t"+op+"\n";
}

function unary(x, cl) {
  var pr = ''; 
  var po = '';
  if (cl) {
    pr = "<span class='"+cl+"'>";
    po = "</span>";
  }
  return "\t"+pr+x+po+"\n";
}

function label(x, cl) {
  var pr = ''; 
  var po = '';
  if (cl) {
    pr = "<span class='"+cl+"'>";
    po = "</span>";
  }
  return pr+":"+x+po+"\n"; 
}

function functionCall(name, arglist) {
  var info = findSymbol(name);
  var s = info[1];
  info = info[0];

  if (!info || info.type != 'FUNC') {
    throw new Error("Can't call '"+name+"' ");
  }
  else if(arglist.length != info.arity) {
    throw new Error("Can't call '"+name+"' with "+arglist.length+
                    " arguments. Expected "+info.arity+" arguments.");
  }
  //!!!!!!!!!!
  return arglist.join('')+unary("call "+":"+findFuncName(symbolTable[name].symbolTable),"jump");
}
 
function findFuncName(n) {
  var f = n;
  var name = f.name;
  while (f.name != '') {
    f = f.father;
    if (f.name != '') name = f.name+"_"+name;
  }
  return name;
}

function translateFunction(name, parameters, decs, statements) {

  symbolTable[name] = $.extend({}, symbolTable[name], { 
    decs: decs,
    parameters: parameters, 
    arity: parameters.length,
    statements: statements 
  });

  return unary("args "+ parameters.join(','))+
         decs.join('')+
         label(findFuncName(symbolTable[name].symbolTable), 'jump')+
         statements.join('')+
         unary('return', 'jump'); 
}

%}

/* operator associations and precedence */

%token IF ELSE THEN DEF PI E ID NUMBER EOF

%nonassoc ID
%nonassoc "("

%left THEN
%right ELSE

%right "="
%left "<=" ">=" "==" "!=" "<" ">" 
%left "+" "-"
%left "*" "/"
%left "^"
%left "!"
%right "%"
%left UMINUS

%start prog

%% /* language grammar */
prog
    : decs statements EOF
        { 
          var decs = $decs.join('');
          var sts = label("main:",'jump')+$statements.join("");
          console.log(decs);
          console.log(sts);
          return decs+sts;
        }
    ;

decs
    : /* empty */ { $$ = []; }
    | decs dec    { $$ = $1; $$.push($2); }
    ;

dec 
    : DEF functionname  optparameters "{" decs statements "}" 
                  { 
                     getFormerScope();

                     $$ = translateFunction($functionname, 
                                            $optparameters, 
                                            $decs,
                                            $statements); 
                  }
    | VAR varlist ';'   { 
                           for(var i in $varlist) {
                             symbolTable[$varlist[i]] = { type:  "VAR" }; 
                           }
                           $$ = unary('var '+$varlist.join(',')); 
                        }
    ;

varlist 
    : optinitialization                    { $$ = [ $optinitialization ]; }
    | optinitialization ',' varlist        { $$ = $1; $$.push($varlist); }
    ;

optinitialization
    : ID          {
                     $$ = [$ID];
                  }
    | ID '=' e 
                  {
                    $$ = [$ID];
                  }
    ;

functionname
    : ID 
                  {
                     if (symbolTable[$ID]) 
                       throw new Error("Function "+$ID+" defined twice");
                     symbolTable[$ID] = { type: 'FUNC', name: $ID };

                     makeNewScope($ID);

                     $$ = $ID;
                  }
    ;

optparameters
    : /* empty */            { $$ = []; }
    | parameters
    | "(" parameters ")"     { $$ = $parameters; }
    ;
        
parameters
    : ID                      { 
                                 $symbolTable[$ID] = { type : 'PARAM' };
                                 $$ = [ $ID ]; 
                              }
    | parameters "," ID       { 
                                 $symbolTable[$ID] = { type : 'PARAM' };
                                 $$ = $1; 
                                 $$.push($ID); 
                               }
    ;

statements
    : s  
        { $$ = $1? [ $1 ] : []; }
    | statements ";" s
        { $$ = $1;
          if ($3) $$.push($3); 
          console.log($$);
        }
    ;

s
    : /* empty */ { $$ = ''; }
    | e
    | IF e THEN s
        { $$ = translateIf($e, $s); }
    | IF e THEN s ELSE s
        { $$ = translateIfElse($e, $s1, $s2); }
    ;

e
    : ID "=" e
        { 
           // si ID es FUNC o es un PARAM que pasa?
           // declaralo solo si no ha sido declarado anteriormente
           var info = findSymbol($ID);
           var s = info[1];
           info = info[0];

           if (info && info != 'FUNC') { // already declared/initialized
             $$ = binary($e,unary("&"+$ID+", "+(getScope()-s)), "=");
           }
           else { // !info: declare as local variable or 
                  // info != 'FUNC': was declared as a FUNC
             symbolTable[$ID] = "VAR"; 
             $$ = binary($3,unary("&"+$1+", "+(getScope()-s), "="));
           }
        }
    | PI "=" e 
        { throw new Error("Can't assign to constant 'π'"); }
    | e "<=" e
        { $$ = binary($1,$3, "<=");}
    | e ">=" e
        { $$ = binary($1,$3, ">=");}
    | e "<" e
        { $$ = binary($1,$3, "<");}
    | e ">" e
        { $$ = binary($1,$3, ">");}
    | e "==" e
        { $$ = binary($1,$3, "==");}
    | e "+" e
        { $$ = binary($1,$3, "+");}
    | e "*" e
        { $$ = binary($1,$3, "*");}
    | e "/" e
        { $$ = binary($1,$3, "/");}
    | "(" e ")"
        { $$ = $2;}
    | ID "(" optarglist ")"
        { $$ = functionCall($ID, $optarglist); }
    | NUMBER
        { $$ = unary($NUMBER);}
    | E
        { $$ = unary(Math.E);}
    | PI
        { $$ = unary(Math.PI);}
    | ID 
        { 
          // what if it is a FUNC or a LOCAL or a GLOBAL? or not defined?
          var info = findSymbol($ID);
          var s = info[1];
          info = info[0];

          if (info && info.type == 'PARAM') {
            $$ = unary('$'+$ID+", "+(getScope()-s));
          }
          else {
            $$ = unary($ID+", "+(getScope()-s));
          }
        }
    ;

optarglist 
    : /* empty */  {  $$ = []; }
    | arglist      
    ;

arglist
    : e               { $$ = [ $e ]; }
    | arglist ',' e   { $$ = $arglist; $$.push($e); }
    ;
