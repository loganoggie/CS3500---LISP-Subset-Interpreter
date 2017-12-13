/*
      mfpl.y

 	Specifications for the MFPL language, bison input file.

      To create syntax analyzer:

        flex mfpl.l
        bison mfpl.y
        g++ mfpl.tab.c -o mfpl_parser
        mfpl_parser < inputFileName
 */

/*
 *	Declaration section.
 */
%{
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <string>
#include <string.h>
#include <stack>
#include <ctype.h>
#include "SymbolTable.h"
using namespace std;

#define ARITHMETIC_OP	1   // classification for operators
#define LOGICAL_OP   	2
#define RELATIONAL_OP	3

int lineNum = 1;

stack<SYMBOL_TABLE> scopeStack;    // stack of scope hashtables

bool isIntCompatible(const int theType);
bool isStrCompatible(const int theType);
bool isIntOrStrCompatible(const int theType);

void beginScope();
void endScope();
void cleanUp();
TYPE_INFO findEntryInAnyScope(const string theName);

void printRule(const char*, const char*);
int yyerror(const char* s) {
  printf("Line %d: %s\n", lineNum, s);
  cleanUp();
  exit(1);
}

extern "C" {
    int yyparse(void);
    int yylex(void);
    int yywrap() {return 1;}
}

%}

%union {
  char* text;
  int num;
  TYPE_INFO typeInfo;
};

/*
 *	Token declarations
*/
%token  T_LPAREN T_RPAREN
%token  T_IF T_LETSTAR T_PRINT T_INPUT
%token  T_ADD  T_SUB  T_MULT  T_DIV
%token  T_LT T_GT T_LE T_GE T_EQ T_NE T_AND T_OR T_NOT
%token  T_INTCONST T_STRCONST T_T T_NIL T_IDENT T_UNKNOWN

%type  <text>      T_IDENT T_INTCONST T_STRCONST T_T T_NIL
%type  <typeInfo>  N_EXPR N_PARENTHESIZED_EXPR N_ARITHLOGIC_EXPR
%type  <typeInfo>  N_CONST N_IF_EXPR N_PRINT_EXPR N_INPUT_EXPR
%type  <typeInfo>  N_LET_EXPR N_EXPR_LIST N_BIN_OP
%type  <text>      N_ARITH_OP T_ADD T_SUB T_MULT T_DIV
%type  <text>      N_REL_OP T_LT T_GT T_LE T_GE T_EQ T_NE
%type  <text>      N_LOG_OP T_AND T_OR

/*
 *	Starting point.
 */
%start  N_START

/*
 *	Translation rules.
 */
%%
N_START		: N_EXPR
			{
			printRule("START", "EXPR");
			printf("\n---- Completed parsing ----\n\n");
            printf("\nValue of the expression is: %s", $1.value);
			return 0;
			}
			;
N_EXPR		: N_CONST
			{
			    printRule("EXPR", "CONST");
			    $$.type = $1.type;
                $$.value = $1.value;
			}
            | T_IDENT
            {
    			printRule("EXPR", "IDENT");
                string ident = string($1);
                TYPE_INFO exprTypeInfo = findEntryInAnyScope(ident);
                if (exprTypeInfo.type == UNDEFINED)
                {
                    yyerror("Undefined identifier");
                    return(0);
                }
                $$.type = exprTypeInfo.type;
			}
            | T_LPAREN N_PARENTHESIZED_EXPR T_RPAREN
            {
			    printRule("EXPR", "( PARENTHESIZED_EXPR )");
			    $$.type = $2.type;
                $$.value = $2.value;
			}
			;
N_CONST		: T_INTCONST
			{
			    printRule("CONST", "INTCONST");
                $$.type = INT;
                $$.value = $1;
			}
            | T_STRCONST
			{
			    printRule("CONST", "STRCONST");
            	$$.type = STR;
                $$.value = $1;
			}
            | T_T
            {
			    printRule("CONST", "t");
                $$.type = BOOL;
                $$.value = $1;
			}
            | T_NIL
            {
			    printRule("CONST", "nil");
			    $$.type = BOOL;
                $$.value = $1;
			}
			;
N_PARENTHESIZED_EXPR : N_ARITHLOGIC_EXPR
				{
				    printRule("PARENTHESIZED_EXPR", "ARITHLOGIC_EXPR");
				    $$.type = $1.type;
                    $$.value = $1.value;
				}
                | N_IF_EXPR
				{
				    printRule("PARENTHESIZED_EXPR", "IF_EXPR");
				    $$.type = $1.type;
                    $$.value = $1.value;
				}
                | N_LET_EXPR
				{
				    printRule("PARENTHESIZED_EXPR", "LET_EXPR");
				    $$.type = $1.type;
                    $$.value = $1.value;
				}
                | N_PRINT_EXPR
				{
				    printRule("PARENTHESIZED_EXPR", "PRINT_EXPR");
				    $$.type = $1.type;
                    $$.value = $1.value;
				}
                | N_INPUT_EXPR
				{
				    printRule("PARENTHESIZED_EXPR", "INPUT_EXPR");
				    $$.type = $1.type;
                    $$.value = $1.value;
				}
                | N_EXPR_LIST
				{
				    printRule("PARENTHESIZED_EXPR", "EXPR_LIST");
				    $$.type = $1.type;
                    $$.value = $1.value;
				}
				;
N_ARITHLOGIC_EXPR : N_UN_OP N_EXPR
				{
				    printRule("ARITHLOGIC_EXPR", "UN_OP EXPR");
                    $$.type = BOOL;

                    string nil = "nil";
                    const char * tmpNil = nil.c_str();
                    string t = "t";
                    const char * tmpT = t.c_str();
                    /*
                    if(strcmp($2.value, tmpNil) != 0)
                    {
                        sprintf($$.value, "%s", tmpT);
                    }
                    else
                    {
                        sprintf($$.value, "%s", tmpNil);
                    }
                    */
                    // sprintf($$.value, "%s", tmpNil);

                    // TODO: FINISH THIS NONTERMINAL!!
				}
				| N_BIN_OP N_EXPR N_EXPR
				{
				    printRule("ARITHLOGIC_EXPR", "BIN_OP EXPR EXPR");
                    $$.type = BOOL;
                    switch ($1.type)
                    {
                        case (ARITHMETIC_OP) :
                        {
                            $$.type = INT;
                            if (!isIntCompatible($2.type))
                            {
                                yyerror("Arg 1 must be integer");
                                return(0);
                         	}
                         	if (!isIntCompatible($3.type))
                            {
                                yyerror("Arg 2 must be integer");
                                return(0);
                         	}

                            const char* tmp2 = const_cast<const char*>($2.value);
                            const char* tmp3 = const_cast<const char*>($3.value);

                            int arg1 = atoi(tmp2);
                            int arg2 = atoi(tmp3);
                            int result;

                            if(*$1.value == '+')
                            {
                                result = arg1+arg2;
                            }
                            else if(*$1.value == '-')
                            {
                                result = arg1-arg2;
                            }
                            else if(*$1.value == '*')
                            {
                                result = arg1*arg2;
                            }
                            else if(*$1.value == '/')
                            {
                                if(arg2 == 0)
                                {
                                    yyerror("Attempted division by zero");
                                }
                                result = arg1/arg2;
                            }
                            sprintf($$.value, "%d", result);
                            break;
                        }
				        case (LOGICAL_OP) :
                        {
                            string andOp = "and";
                            string orOp = "or";
                            string nil = "nil";
                            const char * tmpNil = nil.c_str();
                            string t = "t";
                            const char * tmpT = t.c_str();

                            if(andOp == $1.value)
                            {
                                if(nil == $2.value || nil == $3.value)
                                {
                                    sprintf($$.value, "%s", tmpNil);
                                }
                                else
                                {
                                    sprintf($$.value, "%s", tmpT);
                                }
                            }
                            else if(orOp == $1.value)
                            {
                                if(nil == $2.value && nil == $3.value)
                                {
                                    sprintf($$.value, "%s", tmpNil);
                                }
                                else
                                {
                                    sprintf($$.value, "%s", tmpT);
                                }
                            }

                            break;
                        }
                        case (RELATIONAL_OP) :
                            if (!isIntOrStrCompatible($2.type))
                            {
                                yyerror("Arg 1 must be integer or string");
                                return(0);
                            }
                            if (!isIntOrStrCompatible($3.type))
                            {
                                yyerror("Arg 2 must be integer or string");
                                return(0);
                            }
                            if (isIntCompatible($2.type) && !isIntCompatible($3.type))
                            {
                                yyerror("Arg 2 must be integer");
                                return(0);
                     	    }
                            else if (isStrCompatible($2.type) && !isStrCompatible($3.type))
                            {
                               yyerror("Arg 2 must be string");
                               return(0);
                            }

                            string nil = "nil";
                            const char * tmpNil = nil.c_str();
                            string t = "t";
                            const char * tmpT = t.c_str();
                            string tmplt = "<";
                            const char * lt = tmplt.c_str();
                            string tmpgt = ">";
                            const char * gt = tmpgt.c_str();
                            string tmpeq = "=";
                            const char * eq = tmpeq.c_str();
                            string tmpneq = "/=";
                            const char * neq = tmpneq.c_str();
                            string tmpgteq = ">=";
                            const char * gteq = tmpgteq.c_str();
                            string tmplteq = "<=";
                            const char * lteq = tmplteq.c_str();


                            if($2.type == INT)
                            {
                                const char* tmp2 = const_cast<const char*>($2.value);
                                const char* tmp3 = const_cast<const char*>($3.value);

                                int arg1 = atoi(tmp2);
                                int arg2 = atoi(tmp3);

                                if(strcmp($1.value, lt) != 0)
                                {
                                    if(arg1 < arg2)
                                        sprintf($$.value, "%s", tmpT);
                                    else
                                        sprintf($$.value, "%s", tmpNil);
                                }
                                else if(strcmp($1.value, gt) != 0)
                                {
                                    if(arg1 > arg2)
                                        sprintf($$.value, "%s", tmpT);
                                    else
                                        sprintf($$.value, "%s", tmpNil);
                                }
                                else if(strcmp($1.value, lteq) != 0)
                                {
                                    if(arg1 <= arg2)
                                        sprintf($$.value, "%s", tmpT);
                                    else
                                        sprintf($$.value, "%s", tmpNil);
                                }
                                else if(strcmp($1.value, gteq) != 0)
                                {
                                    if(arg1 >= arg2)
                                        sprintf($$.value, "%s", tmpT);
                                    else
                                        sprintf($$.value, "%s", tmpNil);
                                }
                                else if(strcmp($1.value, eq) != 0)
                                {
                                    if(arg1 == arg2)
                                        sprintf($$.value, "%s", tmpT);
                                    else
                                        sprintf($$.value, "%s", tmpNil);
                                }
                                else if(strcmp($1.value, neq) != 0)
                                {
                                    if(arg1 != arg2)
                                        sprintf($$.value, "%s", tmpT);
                                    else
                                        sprintf($$.value, "%s", tmpNil);
                                }
                            }
                            else
                            {
                                const char* tmp2 = const_cast<const char*>($2.value);
                                const char* tmp3 = const_cast<const char*>($3.value);

                                string arg1 = string(tmp2);
                                string arg2 = string(tmp3);

                                if(strcmp($1.value, eq) != 0)
                                {
                                    if(arg1 == arg2)
                                        sprintf($$.value, "%s", tmpNil);
                                    else
                                        sprintf($$.value, "%s", tmpT);
                                }
                                else if(strcmp($1.value, neq) != 0)
                                {
                                    if(arg1 != arg2)
                                        sprintf($$.value, "%s", tmpNil);
                                    else
                                        sprintf($$.value, "%s", tmpT);
                                }
                            }
                            break;
                        }  // end switch
				   }
            ;
N_IF_EXPR   : T_IF N_EXPR N_EXPR N_EXPR
			{
			    printRule("IF_EXPR", "if EXPR EXPR EXPR");
                string nil = "nil";
                const char * tmpNil = nil.c_str();
                if(nil == $2.value)
                {
                    $$.type = $4.type;
                    $$.value = $4.value;
                }
                else
                {
                    $$.type = $3.type;
                    $$.value = $3.value;
                }
			}
			;
N_LET_EXPR  : T_LETSTAR T_LPAREN N_ID_EXPR_LIST T_RPAREN N_EXPR
			{
			    printRule("LET_EXPR", "let* ( ID_EXPR_LIST ) EXPR");
			    endScope();
                $$.type = $5.type;
                $$.value = $5.value;
			}
			;
N_ID_EXPR_LIST  : /* epsilon */
			{
			    printRule("ID_EXPR_LIST", "epsilon");
			}
            | N_ID_EXPR_LIST T_LPAREN T_IDENT N_EXPR T_RPAREN
			{
			    printRule("ID_EXPR_LIST", "ID_EXPR_LIST ( IDENT EXPR )");
			    string lexeme = string($3);
                TYPE_INFO exprTypeInfo = $4;
                printf("___Adding %s to symbol table\n", $3);
                bool success = scopeStack.top().addEntry(SYMBOL_TABLE_ENTRY(lexeme, exprTypeInfo));
                if (! success)
                {
                   yyerror("Multiply defined identifier");
                   return(0);
                }

                // TODO: FINISH THIS NONTERMINAL!!
			}
			;
N_PRINT_EXPR : T_PRINT N_EXPR
			{
			    printRule("PRINT_EXPR", "print EXPR");
                $$.type = $2.type;
                $$.value = $2.value;
                cout << $2.value << endl;
			}
			;
N_INPUT_EXPR : T_INPUT
			{
                char inputData[1000];
                printRule("INPUT_EXPR", "input");

                cin.getline(inputData, 1000);
                if(inputData[0] == '+' || inputData[0] == '-' || inputData[0] == '0' || inputData[0] == '1'
                || inputData[0] == '2' || inputData[0] == '3' || inputData[0] == '4' || inputData[0] == '5'
                || inputData[0] == '6' || inputData[0] == '7' || inputData[0] == '8' || inputData[0] == '9')
                {
                    $$.type = INT;
                }
                else
                {
                    $$.type = STR;
                }
			}
			;
N_EXPR_LIST : N_EXPR N_EXPR_LIST
			{
			    printRule("EXPR_LIST", "EXPR EXPR_LIST");
                $$.type = $2.type;
                $$.value = $2.value;
			}
            | N_EXPR
			{
			    printRule("EXPR_LIST", "EXPR");
                $$.type = $1.type;
                $$.value = $1.value;
			}
			;
N_BIN_OP    : N_ARITH_OP
			{
			    printRule("BIN_OP", "ARITH_OP");
			    $$.type = ARITHMETIC_OP;
                $$.value = $1;
			}
			| N_LOG_OP
			{
			    printRule("BIN_OP", "LOG_OP");
			    $$.type = LOGICAL_OP;
                $$.value = $1;
			}
			| N_REL_OP
			{
			    printRule("BIN_OP", "REL_OP");
			    $$.type = RELATIONAL_OP;
                $$.value = $1;
			}
			;
N_ARITH_OP	: T_ADD
			{
			    printRule("ARITH_OP", "+");
                $$ = $1;
			}
            | T_SUB
			{
			    printRule("ARITH_OP", "-");
                $$ = $1;
			}
			| T_MULT
			{
			    printRule("ARITH_OP", "*");
                $$ = $1;
			}
			| T_DIV
			{
			    printRule("ARITH_OP", "/");
                $$ = $1;
			}
			;
N_REL_OP    : T_LT
			{
			    printRule("REL_OP", "<");
                $$ = $1;
			}
			| T_GT
			{
			    printRule("REL_OP", ">");
                $$ = $1;
			}
			| T_LE
			{
			    printRule("REL_OP", "<=");
                $$ = $1;
			}
			| T_GE
			{
			    printRule("REL_OP", ">=");
                $$ = $1;
			}
			| T_EQ
			{
			    printRule("REL_OP", "=");
                $$ = $1;
			}
			| T_NE
			{
			    printRule("REL_OP", "/=");
                $$ = $1;
			}
			;
N_LOG_OP	: T_AND
			{
			    printRule("LOG_OP", "and");
                $$ = $1;
			}
			| T_OR
			{
			    printRule("LOG_OP", "or");
                $$ = $1;
			}
			;
N_UN_OP	    : T_NOT
			{
			    printRule("UN_OP", "not");
			}
			;
%%

#include "lex.yy.c"
extern FILE *yyin;

bool isIntCompatible(const int theType)
{
    return((theType == INT) || (theType == INT_OR_STR) ||
           (theType == INT_OR_BOOL) || (theType == INT_OR_STR_OR_BOOL));
}

bool isStrCompatible(const int theType)
{
    return((theType == STR) || (theType == INT_OR_STR) ||
         (theType == STR_OR_BOOL) || (theType == INT_OR_STR_OR_BOOL));
}

bool isIntOrStrCompatible(const int theType)
{
    return(isStrCompatible(theType) || isIntCompatible(theType));
}

void printRule(const char* lhs, const char* rhs)
{
    printf("%s -> %s\n", lhs, rhs);
    return;
}

void beginScope()
{
    scopeStack.push(SYMBOL_TABLE());
    printf("\n___Entering new scope...\n\n");
}

void endScope()
{
    scopeStack.pop();
    printf("\n___Exiting scope...\n\n");
}

TYPE_INFO findEntryInAnyScope(const string theName)
{
    TYPE_INFO info = {UNDEFINED};
    if (scopeStack.empty( )) return(info);
    info = scopeStack.top().findEntry(theName);
    if (info.type != UNDEFINED)
        return(info);
    else
    { // check in "next higher" scope
	    SYMBOL_TABLE symbolTable = scopeStack.top( );
	    scopeStack.pop( );
	    info = findEntryInAnyScope(theName);
	    scopeStack.push(symbolTable); // restore the stack
	    return(info);
    }
}

void cleanUp()
{
    if (scopeStack.empty())
        return;
    else
    {
        scopeStack.pop();
        cleanUp();
    }
}

int main(int argc, char** argv)
{
    if (argc < 2)
    {
        printf("You must specify a file in the command line!\n");
        exit(1);
    }
    yyin = fopen(argv[1], "r");
    do
    {
        yyparse();
    } while (!feof(yyin));
    return 0;
}
