/******************************************************************************
 *
 * 
 *
 * Copyright (C) 2016 Herman Lundkvist <herlu184@student.liu.se>
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation under the terms of the GNU General Public License is hereby 
 * granted. No representations are made about the suitability of this software 
 * for any purpose. It is provided "as is" without express or implied warranty.
 * See the GNU General Public License for more details.
 *
 * Documents produced by Doxygen are derivative works derived from the
 * input used in their production; they are not affected by this license.
 *
 */

/** \file adaparser.h
 * \brief Ada Language parser using flex and bison.
 *
 * This is the Ada language parser for doxygen.
 */
#ifndef ADAPARSER_H
#define ADAPARSER_H

#include "parserintf.h"
#include <list>
#include <qfile.h>
#include "arguments.h"
#include "entry.h"

/*
inline void dealloc(void *memPtr)
{
  if (memPtr)
  {
    delete memPtr;
    memPtr = NULL;
  }
}
*/

/*
template<typename T>
void dealloc(T*& memPtr);

*/

template<typename T>
void dealloc(T*& memPtr)
{
  if (memPtr)
  {
    delete memPtr;
    memPtr = NULL;
  }
}

/** \brief A struct representing an Identifier (for members, functions,
 *  or classes) that can be referenced in the code. */
struct Identifier
{
  Identifier(QCString str_, int line_, int col_);
  Identifier(QCString str_);

  QCString str;
  /** the line at which the identifer  was found.
   *
   * TODO 2016-08-11 make bison compute this correctly.*/
  int line;
  /** the column at which the identifier was found
   *
   * TODO 2016-08-11 make bison compute this correctly.*/
  int col;

  void print(std::string pad="");
};

typedef std::list<Identifier> Identifiers;
typedef Identifiers::iterator IdentifiersIter;

/** \brief A struct representing an Ada expression */
struct Expression
{
  Expression(){};
  Expression(QCString str_);
  Expression(QCString str_, Identifier id);
  Identifiers ids;
  QCString str;
};

/** \brief A struct for passing referenced Identifiers along
 * with an argumentList in the bison grammar.*/
struct Parameters
{
  Parameters()
  {
    args = new ArgumentList;
    type = NULL;
  }

  ~Parameters()
  {
    dealloc(type);
  }

  Identifiers refs;
  ArgumentList *args;
  Expression *type;
};

enum NodeType
{
  ADA_PKG,
  ADA_VAR,
  ADA_SUBPROG,
  ADA_RECORD,
  ADA_TYPE,
  ADA_ENUM,
  ADA_UNKNOWN
};

/** \brief a node in the ADA AST.
 *
 * RuleHandler and its derivaties operate on node and derivaties
 * of it.*/
class Node
{
public:
  virtual void addChild(Node *child)=0;
  virtual void print() = 0;
  virtual Node *clone() = 0;
};

/** \brief wrapper for entity.
 * 
 * This is used by EntryNodeHandler.*/
class EntryNode: public Node
{
public:
  EntryNode();
  EntryNode(Entry &entryRef);
  virtual void addChild(Node *child);
  virtual void print();
  virtual Node *clone();
  Entry &entry;
};

typedef std::list<EntryNode*> Entries;
typedef Entries::iterator EntriesIter;

/** \brief an entity used in "Code parsing".
 *
 * stores data needed to compute links between entities.*/
class CodeNode: public Node
{
public:
  NodeType type;
  QCString name;
  QCString name_space;
  Identifiers refs;
  std::list<CodeNode*> children;

  CodeNode();
  CodeNode(
    NodeType type,
    const QCString &name, const QCString &name_space);
  virtual void addChild(Node *child);
  virtual void print();
  virtual Node *clone();
  void appendRefs(Identifiers &new_refs);
private:
  void print_(std::string pad);
};

typedef std::list<CodeNode*> CodeNodes;
typedef CodeNodes::iterator CodeNodesIter;

/** \brief a struct for marking special syntax symbols
 *
 * Contains a location of the symbol and how the
 * TODO 2016-08-11: Not used. Inteded for syntax highligting 
 */
struct syntaxSymbol
{
  int line_n;
  int col;
};

typedef std::list<Node*> Nodes;
typedef Nodes::iterator NodesIter;
typedef std::list<syntaxSymbol> SyntaxSymbols;
typedef SyntaxSymbols::iterator SyntaxSymbolsIter;

class AdaLanguageScanner : public ParserInterface
{
  public:
    AdaLanguageScanner(){}
    virtual ~AdaLanguageScanner() {}
    //TODO 2016-08-11: Not Implemented. Check if it is needed
    //by doxygen.
    void startTranslationUnit(const char *) {}
    //TODO 2016-08-11: Not Implemented. Check if it is needed
    //by doxygen.
    void finishTranslationUnit() {}
    void parseInput(const char * fileName, 
                    const char *fileBuf, 
                    Entry *root,
                    bool sameTranslationUnit,
                    QStrList &filesInSameTranslationUnit);
    bool needsPreprocessing(const QCString &extension);
    void parseCode(CodeOutputInterface &codeOutIntf,
                   const char *scopeName,
                   const QCString &input,
                   SrcLangExt lang,
                   bool isExampleBlock,
                   const char *exampleName=0,
                   FileDef *fileDef=0,
                   int startLine=-1,
                   int endLine=-1,
                   bool inlineFragment=FALSE,
                   MemberDef *memberDef=0,
                   bool showLineNumbers=TRUE,
                   Definition *searchCtx=0,
                   bool collectXrefs=TRUE
                  );
    //TODO 2016-08-11: Not Implemented. Check if it is needed
    //by doxygen.
    void resetCodeParserState();
    //TODO 2016-08-11: Not Implemented. Check if it is needed
    //by doxygen.
    void parsePrototype(const char *text);
  private:
    QFile inputFile;
    QCString qcFileName;
};

/*
 * Ada scanner functions
 */
/** \brief point the scanner to a string that should be parsed.
 *
 * Doxygen reads the file contents and passes it as a string
 * to the ada Parser.*/
void setInputString(const char* input);

/** \brief Frees resources used by the scanner.
 *
 * Should be called when parsing is finished.*/
void adaScannerCleanup();

/** \brief reset input buffers used by the scanner.*/
void cleanupInputString();

//TODO 2016-08-11: Not Implemented, might be needed in the future.
void adaFreeScanner();

/** \brief Initilize the Ada scanner.
 *
 * This function should be called before calling adaYYparse() */
void initAdaScanner(AdaLanguageScanner *parser, QCString fileName,
                    bool should_save_comments);

/** \brief get the structural comments identified by the scanner.
 *
 * The scanner identifies all doxy comments and determines if they are
 * structural or not. Structural comments no not depend
 * on location in the syntax tree, and are thus handeled by the scanner.
 * Non-structural comments o.t.h. are handeled by the parser.*/
const Entries& getStructDoxyComments();


/*
 * Helper functions used by the Ada scanner and Ada parser.
 */


QCString adaArgListToString(const ArgumentList &args);

void initEntry (Entry &e, Entry *parent=NULL, Protection prot=Public,
                MethodTypes mtype=Method, bool stat=false,
                Specifier virt=Normal);




void printIds(Identifiers* ids, std::string pad="");

inline Expression *moveExprIds(Expression *dst, Expression *src)
{
  dst->ids.splice(dst->ids.begin(), src->ids);
  dealloc(src);
  return dst;
}

inline Identifiers *moveExprToIds(Identifiers *dst, Expression *src)
{
  dst->splice(dst->begin(), src->ids);
  dealloc(src);
  return dst;
}

inline Identifiers *moveIds(Identifiers *dst, Identifiers *src)
{
  dst->splice(dst->begin(), *src);
  dealloc(src);
  return dst;
}

inline Expression* exprPair(Expression *e1, Expression *e2, QCString sep="")
{
    e1->str.append (sep);
    e1->str.append(e2->str);
    moveExprIds(e1, e2);
    return e1;
}


inline void printNodes(Nodes* nodes)
{
  if (nodes && !nodes->empty())
  {
    printf("PRINTING NODES\n");
    printf("START\n");
    NodesIter it = nodes->begin();
    for (;it != nodes->end();++it)
    {
      (*it)->print();
    }
    printf("END\n");
  }
  else
      printf("Nodes empty\n");

}

#endif //ADAPARSER_H
