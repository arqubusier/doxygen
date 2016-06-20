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
/*  This code is based on the work done by the MoxyPyDoxy team
 *  (Linda Leong, Mike Rivera, Kim Truong, and Gabriel Estrada)
 *  in Spring 2005 as part of CS 179E: Compiler Design Project
 *  at the University of California, Riverside; the course was
 *  taught by Peter H. Froehlich <phf@acm.org>.
 */


#ifndef ADAPARSER_H
#define ADAPARSER_H

#include "parserintf.h"
#include <qfile.h>

/** \brief Ada Language parser using state-based lexical scanning.
 *
 * This is the Ada language parser for doxygen.
 */
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
    //TODO IMPLEMENT
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
};

void adaFreeScanner();
void setInputString(const char* input);
void cleanupInputString();

#endif //ADAPARSER_H