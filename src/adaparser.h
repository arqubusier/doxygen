/******************************************************************************
 *
 * 
 *
 * Copyright (C) 1997-2015 by Dimitri van Heesch.
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

#ifndef ADAPARSER_H
#define ADAPARSER_H

#include "parserintf.h"
#include <list>
#include <qfile.h>
#include "arguments.h"
#include "entry.h"

/** \brief Ada Language parser using flex and bison.
 *
 * This is the Ada language parser for doxygen.
 */


struct Identifier
{
  Identifier(QCString str_, int line_, int col_);
  Identifier(QCString str_);

  QCString str;
  int line;
  int col;

  void print(std::string pad="");
};

typedef std::list<Identifier> Identifiers;
typedef Identifiers::iterator IdentifiersIter;

struct Expression
{
  Identifiers ids;
  QCString str;
};

struct Parameters
{
  Parameters()
  {
    args = new ArgumentList;
    refs = new Identifiers;
  }

  Identifiers *refs;
  ArgumentList *args;
};

enum NodeType
{
  ADA_PKG,
  ADA_VAR,
  ADA_SUBPROG,
  ADA_RECORD,
  ADA_UNKNOWN
};

/** \brief a node in the ADA AST.*/
class Node
{
public:
  virtual void addChild(Node *child)=0;
  virtual void print() = 0;
};

/** \brief wrapper for entity.*/
class EntryNode: public Node
{
public:
  EntryNode();
  EntryNode(Entry &entryRef);
  virtual void addChild(Node *child);
  virtual void print();
  Entry &entry;
};

typedef std::list<EntryNode*> Entries;
typedef Entries::iterator EntriesIter;

/** \brief an entity used in "Code parsing".
 *
 * stores data needed to compute
 * links between entities.
 * and syntax highlighing*/
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
  void appendRefs(Identifiers *new_refs);
private:
  void print_(std::string pad);
};

typedef std::list<CodeNode*> CodeNodes;
typedef CodeNodes::iterator CodeNodesIter;

/** \brief a struct for marking special syntax symbols
 *
 * Contains a location of the symbol and how the
 * symbol should be handeled.
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
    void startTranslationUnit(const char *) {}
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
    void resetCodeParserState();
    void parsePrototype(const char *text);
    bool setFile(const char* fileName);
    void restartScanner();
    void cleanFile();
    void read();
  private:
    QFile inputFile;
    QCString qcFileName;
};

void freeAdaScanner();
void setInputString(const char* input);
void cleanupInputString();
void adaFreeScanner();

void initAdaScanner(AdaLanguageScanner *parser, QCString fileName,
                    bool should_save_comments);
QCString adaArgListToString(const ArgumentList &args);

const Entries& getStructDoxyComments();
void resetStructDoxyComments();

void initEntry (Entry &e, Entry *parent=NULL, Protection prot=Public,
                MethodTypes mtype=Method, bool stat=false,
                Specifier virt=Normal);
#endif //ADAPARSER_H
