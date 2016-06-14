#ifndef DBG_UTIL_H
#define DBG_UTIL_H
#include <string> 
#include <qcstring.h> 
#include "arguments.h"

void printQC(std::string pad, std::string name, QCString &str);
void printFlag(std::string pad, std::string name, bool flag);
void printArgs(std::string pad,  ArgumentList *al);
#endif //DBG_UTIL_H
