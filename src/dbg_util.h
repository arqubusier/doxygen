#ifndef DBG_UTIL_H
#define DBG_UTIL_H
#include <string> 
#include <qcstring.h>
#include <qlist.h> 
#include "arguments.h"

void printQC(std::string pad, std::string name, const QCString &str);
void printFlag(std::string pad, std::string name, bool flag);
void printArgs(std::string pad,  ArgumentList *al);
//void printTArgs(std::string pad,  Qlist *tal);
std::string section2str(int sec);
#endif //DBG_UTIL_H
