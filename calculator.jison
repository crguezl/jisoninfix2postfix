/* description: 
   Translates infix expressions to postfix. 
   Implements functions and function calls
*/

%{

var symbolTables = [{ name: '', father: null, vars: {} }];
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
   symbolTable.vars[id].symbolTable = symbolTables[scope] =  { name: id, father: symbolTable, vars: {} };
   symbolTable = symbolTables[scope];
   return symbolTable;
}

function findSymbol(x) {
  var f;
  var s = scope;
  do {
    f = symbolTables[s].vars[x];
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
  return arglist.join('')+unary("call "+":"+findFuncName(findSymbol(name)[0].symbolTable),"jump");
}
 
function findFuncName(n) {
  var f = n;
  var name = f.name;
  while (f.name != '') {
    f = f.father;
    if (f.name != '') name = f.name+"."+name;
  }
  return name;
}

function translateFunction(name, parameters, decs, statements) {

  symbolTable.vars[name] = $.extend({}, symbolTable.vars[name], { 
    decs: decs,
    parameters: parameters, 
    arity: parameters.length,
    statements: statements 
  });

  return unary("args "+ parameters.join(','))+
         decs.join('')+
         label(findFuncName(symbolTable.vars[name].symbolTable), 'jump')+
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
                             var name = $varlist[i][0]; 
                             var initial_value = $varlist[i][1]; 
                             symbolTable.vars[name] = { type:  "VAR", initial_value: initial_value }; 
                           }
                           $$ = unary('var '+$varlist.map(function(x) { return x[0] }).join(',')); 
                        }
    ;

varlist 
    : optinitialization                    { $$ = [ $optinitialization ]; }
    | varlist ',' optinitialization        { $$ = $varlist; $$.push($optinitialization); }
    ;

optinitialization
    : ID          {
                     $$ = [$ID, null ];
                  }
    | ID '=' e 
                  {
                    $$ = [ $ID, $e ];
                  }
    ;

functionname
    : ID 
                  {
                     if (symbolTable.vars[$ID]) 
                       throw new Error("Function "+$ID+" defined twice");
                     symbolTable.vars[$ID] = { type: 'FUNC', name: $ID };

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
                                 $symbolTable.vars[$ID] = { type : 'PARAM' };
                                 $$ = [ $ID ]; 
                              }
    | parameters "," ID       { 
                                 $symbolTable.vars[$ID] = { type : 'PARAM' };
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

           if (info && info.type === 'VAR') { // already declared/initialized
             $$ = binary($e,unary("&"+$ID+", "+(getScope()-s)), "=");
           }
           else if (info && info.type === 'PAR') { 
             $$ = binary($e,unary("&$"+$ID+", "+(getScope()-s)), "=");
           }
           else if (info && info.type === 'FUNC') { 
              throw new Error("Symbol "+$ID+" refers to a function");
           }
           else { 
              throw new Error("Symbol "+$ID+" not declared");
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

          if (info && info.type === 'PARAM') {
            $$ = unary('$'+$ID+", "+(getScope()-s));
          }
          else if (info && info.type === 'VAR') {
            $$ = unary($ID+", "+(getScope()-s));
          }
          else if (info && info.type === 'FUNC') {
            throw new Error("Symbol "+$ID+" refers to a function");
          }
          else {
            throw new Error("Symbol "+$ID+" not declared");
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
