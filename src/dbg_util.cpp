#include "dbg_util.h"
#include <sstream>
#include <iostream>

#include "message.h"


void printQC(std::string pad, std::string name,const QCString &str){
    if (str.isNull())
       return;

    msg("%s%s %s\n", pad.data(), name.data(), str.data());
}

void printFlag(std::string pad, std::string name, bool flag){
   if (flag)
    msg("%s%s TRUE", pad.data(), name.data());
   else
    msg("%s%s FALSE\n", pad.data(), name.data());

}

void printArgs(std::string pad, ArgumentList *al){

 ArgumentListIterator ali(*al);
  Argument *a;
  for (ali.toFirst();(a=ali.current());++ali){
	a->print(pad);
  }
}

//TODO
/*
void printTArgs(std::string pad,  Qlist *tal){
}
*/
std::string section2str(int sec){
    std::stringstream ss;
    std::string s;
    switch(sec){
	case 0x00000001:
		return "CLASS_SEC" ; 
	case 0x00000010:
		return "NAMESPACE_SEC";
	case 0x00000800: 
		return "CLASSDOC_SEC";
	case 0x00001000:
		return "STRUCTDOC_SEC";
	case 0x00002000:
		return "UNIONDOC_SEC";
	case 0x00004000:
		return "EXCEPTIONDOC_SEC";
	case 0x00008000:
		return "NAMESPACEDOC_SEC";
	case 0x00010000:
		return "INTERFACEDOC_SEC";
	case 0x00020000:
		return "PROTOCOLDOC_SEC";
	case 0x00040000:
		return "CATEGORYDOC_SEC";
	case 0x00080000:
		return "SERVICEDOC_SEC";
	case 0x00100000:
		return "SINGLETONDOC_SEC";
	case 0x00400000:
		return "SOURCE_SEC";
	case 0x00800000:
		return "HEADER_SEC";
	case 0x01000000:
		return "ENUMDOC_SEC";
	case 0x02000000:
		return "ENUM_SEC";
	case 0x03000000:
		return "EMPTY_SEC";
	case 0x04000000:
		return "PAGEDOC_SEC";
	case 0x05000000:
		return "VARIABLE_SEC";
	case 0x06000000:
		return "FUNCTION_SEC";
	case 0x07000000:
		return "TYPEDEF_SEC";
	case 0x08000000:
		return "MEMBERDOC_SEC";
	case 0x09000000:
		return "OVERLOADDOC_SEC";
	case 0x0a000000:
		return "EXAMPLE_SEC";
	case 0x0b000000:
		return "VARIABLEDOC_SEC";
	case 0x0c000000:
		return "FILEDOC_SEC";
	case 0x0d000000:
		return "DEFINEDOC_SEC";
	case 0x0e000000:
		return "INCLUDE_SEC";
	case 0x0f000000:
		return "DEFINE_SEC";
	case 0x10000000:
		return "GROUPDOC_SEC";
	case 0x11000000:
		return "USINGDIR_SEC";
	case 0x12000000:
		return "MAINPAGEDOC_SEC";
	case 0x13000000:
		return "MEMBERGRP_SEC";
	case 0x14000000:
		return "USINGDECL_SEC";
	case 0x15000000:
		return "PACKAGE_SEC";
	case 0x16000000:
		return "PACKAGEDOC_SEC";
	case 0x17000000:
		return "OBJCIMPL_SEC";
	case 0x18000000:
		return "DIRDOC_SEC";
	case 0x19000000:
		return ",EXPORTED_INTERFACE_SEC";
	case 0x1A000000:
		return ",INCLUDED_SERVICE_SEC";
	default:{
		ss << sec;
		ss >> s;
		return s;
	}
    }
}
