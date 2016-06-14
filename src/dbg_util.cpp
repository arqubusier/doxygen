#include "dbg_util.h"
#include <iostream>
void printQC(std::string pad, std::string name, QCString &str){
    if (str.isNull())
       return;

    std::cout << pad << name << " " << str << std::endl;
}

void printFlag(std::string pad, std::string name, bool flag){
   if (flag)
     std::cout << pad << name << " true" << std::endl;
   else
     std::cout << pad << name << " false" << std::endl;

}

void printArgs(std::string pad, ArgumentList *al){

 ArgumentListIterator ali(*al);
  Argument *a;
  for (ali.toFirst();(a=ali.current());++ali){
	a->print(pad);
  }
}

