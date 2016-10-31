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

/** \file adarulehandler.cpp
 * \brief Implements methods for EntryRuleHandler and CodeHandler.
 */
#include <stdio.h>
#include "adarulehandler.h"
#include "adaparser.h"
#include "arguments.h"
#include "types.h"
#include "util.h"


/*===================== Helper Functions ====================== */

void addObjRefsToParent(Node* parent, Nodes* decls)
{
  NodesIter nit = decls->begin();
  CodeNode *parentCode = dynamic_cast<CodeNode*>(parent);
  CodeNode *cn;
  for(;nit != decls->end();++nit)
  {
    cn = dynamic_cast<CodeNode*>(*nit);
    if (cn->type == ADA_VAR && &cn->refs && !cn->refs.empty())
    {
      parentCode->appendRefs(cn->refs);
    }
  }
}

/*===================== Rule Handler ========================== */
RuleHandler::RuleHandler(Node *root): m_root(root) {}

RuleHandler::~RuleHandler(){}

void RuleHandler::addToRoot(Node* child)
{
  m_root->addChild(child);
}

void RuleHandler::moveNodes(Nodes* dst,
                           Nodes* src)
{
  dst->splice(dst->begin(), *src);

  dealloc(src);
}

void RuleHandler::moveUnderNode(Node *node, Nodes *nodes)
{
  NodesIter it;
  for (it=nodes->begin(); it!=nodes->end(); ++it)
  {
    node->addChild(*it);
  } 
  dealloc(nodes);
}

Nodes *RuleHandler::declsBase(Node *new_node)
{
  Nodes *es = new Nodes;
  es->push_front(new_node);
  return es;
}

Nodes *RuleHandler::declsBase(Nodes *new_nodes)
{
  Nodes *es = new Nodes;
  moveNodes(es, new_nodes);
  return es;
}

Nodes *RuleHandler::decls(Nodes *nodes, Node *new_node)
{ 
  nodes->push_front(new_node);
  return nodes;
}

Nodes *RuleHandler::decls(Nodes *nodes, Nodes *new_nodes)
{ 
  moveNodes(nodes, new_nodes);
  return nodes;
}

Parameters *RuleHandler::params(Parameters *params, Parameters *new_params)
{
  if (params)
  {
    if (new_params)
    {
      params->refs.splice(params->refs.begin(), (new_params->refs));
      Argument *arg;
      ArgumentListIterator it(*(new_params->args));
      it.toFirst();
      for (; (arg=it.current()); ++it )
      {
          params->args->append(arg);
      }

      dealloc(new_params);
    }
  }
  else
  {
      params = new Parameters;
  }

  return params;
}

Parameters *RuleHandler::paramSpec(Identifiers *ids,
                              Expression *type,
                              QCString *mode,
                              Expression *defval)
{
  Parameters *params = new Parameters;

  IdentifiersIter it = ids->begin();
  for (; it != ids->end(); ++it)
  {
    Argument *a = new Argument;
    if (mode)
    {
      a->type = *mode;
    }
    a->type += " " + type->str;
    a->name = (it->str);
    a->defval = "";
    if (defval){
      a->defval = defval->str;
    }
    params->args->append(a);
  }
  if (mode)
  {
    dealloc( mode);
  }

  if (defval)
  {
    params->refs.splice(params->refs.begin(), defval->ids);
    dealloc( defval);
  }

  params->refs.splice(params->refs.begin(), type->ids);
  dealloc(type);
  return params;
}

Nodes *RuleHandler::component_list(Nodes* item, Nodes* items)
{
    moveNodes(items, item);
    return items;
}

Nodes *RuleHandler::component_list()
{
    return new Nodes();
}


/*===================== Entry Handler ========================== */
EntryHandler::EntryHandler(EntryNode *root): RuleHandler(root) {} 
EntryHandler::EntryHandler(Entry *root): RuleHandler(new EntryNode(*root))
{} 

EntryHandler::~EntryHandler(){}

void EntryHandler::addFileSection(const char *fileName)
{
  int sec = guessSection(fileName);
  if (sec)
  {
    EntryNode *e = newEntryNode();
    e->entry.name = fileName;
    e->entry.section = sec;
    addToRoot(e);
  }
}

Node *EntryHandler::packageSpecBase(const char* name, Nodes *publics, 
                     Nodes *privates) 
{ 
  EntryNode *pkg = newEntryNode(); 
  pkg->entry.section = Entry::NAMESPACE_SEC; 
  pkg->entry.name = QCString(name); 
  pkg->entry.type = QCString("namespace"); 

  NodesIter it = publics->begin(); 
  EntryNode *e;
  for (;it != publics->end(); ++it) 
  {
    e = dynamic_cast<EntryNode*>(*it);
    e->entry.protection = Public; 
  }

  moveUnderNode(pkg, publics); 
  if (privates) 
  { 
    it = privates->begin(); 
    for (;it != privates->end(); ++it) 
      e = dynamic_cast<EntryNode*>(*it);
      e->entry.protection = Private; 
    moveUnderNode(pkg, privates); 
  }    


  dealloc( name);
  return pkg; 
} 


Node* EntryHandler::subprogramSpecBase(QCString *name,
                        Parameters *params)
{
  EntryNode *fun = newEntryNode();
  fun->entry.name = *name;
  dealloc( name);

  if (params)
  {
    fun->entry.argList = params->args;
    fun->entry.args = adaArgListToString(*params->args);

    if (params->type)
    {
      fun->entry.type = params->type->str;
    }
        printf("ccc\n");
    dealloc( params);
        printf("ddd\n");
  }
  fun->entry.section = Entry::FUNCTION_SEC;
  return fun;
}

Node* EntryHandler::subprogramBody(Node *base,
                                   Nodes *decls,
                                   Identifiers *refs)
{
  return base;
}

Nodes *EntryHandler::objDeclBase(Identifiers *refs, Expression *type,
                                 Expression *expr)
{
  Nodes *nodes = new Nodes;

  IdentifiersIter it = refs->begin();
  for (;it != refs->end(); ++it)
  {
    EntryNode *e = newEntryNode();
    e->entry.name = it->str;
    e->entry.type = type->str;
    e->entry.section = Entry::VARIABLE_SEC;
    if (expr)
    {
      // Default value
      //e->entry.args = ":= " + expr->str;
      dealloc( expr);
    }
    nodes->push_front(e);
  }


  dealloc( type);
  dealloc( refs);
  return nodes; 
}

Node *EntryHandler::packageBodyBase(const char* name,
                           Nodes *decls,
                           Identifiers *ids)
{
  EntryNode *pkg = newEntryNode();
  pkg->entry.section = Entry::NAMESPACE_SEC;
  pkg->entry.name = QCString(name);
  pkg->entry.type = QCString("namespace");

  if (decls)
  {
    moveUnderNode(pkg, decls);
  }
  
  dealloc( ids);
  dealloc( name);
  
  return pkg;
}

Node* EntryHandler::full_type_declaration(char *id, Node *def)
{
    if (def){
        EntryNode *e_def = dynamic_cast<EntryNode*>(def);
        e_def->entry.name = id;
    }
    dealloc(id);

    return def;
}

/*
 * Only used for enum definitions
 */
Nodes* EntryHandler::full_type_declarations(char *id, Nodes *defs)
{
    EntryNode *en = newEntryNode();
    en->entry.name = id;
    en->entry.section = Entry::ENUM_SEC;
    en->entry.type = "enum";

    
    NodesIter nit = defs->begin();
    EntryNode *n1;
    EntryNode *n2;
    for(;nit != defs->end();++nit)
    {
        n1 = newEntryNode();
        n2 = dynamic_cast<EntryNode*>(*nit);
        n1->entry.name = n2->entry.name;
        n1->entry.type = n2->entry.type;
        n1->entry.section = n2->entry.section;

        en->addChild(n1);
    }


    defs->push_front(en);

    
    dealloc(id);
    return defs;
}

Nodes *EntryHandler::enumeration_type_definition(Identifiers *ids)
{
  Nodes *nodes = new Nodes();

  IdentifiersIter it = ids->begin();
  for (;it != ids->end(); ++it)
  {
    EntryNode *e = newEntryNode();
    e->entry.name = it->str;
    e->entry.type = "@";
    e->entry.section = Entry::VARIABLE_SEC;
    nodes->push_front(e);
  }

  dealloc(ids);
  return nodes;
}

Node *EntryHandler::record_definition(Nodes *members)
{
   EntryNode* rd = newEntryNode();
   moveUnderNode(rd, members);
   rd->entry.section = Entry::CLASS_SEC;
   rd->entry.type = "record";
   return rd;
}

Node *EntryHandler::record_definition()
{
   EntryNode* rd = newEntryNode();
   rd->entry.section = Entry::CLASS_SEC;
   rd->entry.type = "record";
   return rd;
}

Nodes *EntryHandler::component_declaration(Identifiers *ids, Expression *type,
                             Expression *expr)
{
  Nodes *nodes = new Nodes;

  IdentifiersIter it = ids->begin();
  for (;it != ids->end(); ++it)
  {
    EntryNode *e = newEntryNode();
    e->entry.name = it->str;
    e->entry.type = type->str;
    e->entry.section = Entry::VARIABLE_SEC;
    if (expr)
    {
      // Default value
      //e->entry.args = ":= " + expr->str;
      dealloc( expr);
    }
    nodes->push_front(e);
  }


  dealloc( type);
  dealloc( ids);
  return nodes; 
}

EntryNode* EntryHandler::newEntryNode()
{
    EntryNode* e = new EntryNode;
    initEntry(e->entry);
    return e;
}

void EntryHandler::addDocToEntry(Node *doc, Node *entry){
  if( doc ){
    EntryNode *e_doc = dynamic_cast<EntryNode*>(doc);
    EntryNode *e_entry = dynamic_cast<EntryNode*>(entry);
    e_entry->entry.doc = e_doc->entry.doc;
    e_entry->entry.brief = e_doc->entry.brief;
  }
}

void EntryHandler::addDocToEntries(Node *doc, Nodes* nodes)
{
  if (!nodes->empty())
  {
    Node *node = nodes->back();
    addDocToEntry(doc, node);
  }
}

Node* EntryHandler::type_definition(Expression *def)
{
    EntryNode *e = newEntryNode();
    e->entry.type = def->str;
    e->entry.section = Entry::VARIABLE_SEC;

    dealloc(def);
    return e;
}

Node *EntryHandler::accessToObjectDefinition(Expression *name,
                                        QCString *access_mod)
{
    EntryNode *e = newEntryNode();
    e->entry.type = name->str;
    if (access_mod)
    {
        e->entry.type.prepend(*access_mod);
        dealloc(access_mod);
    }

    e->entry.type.prepend("access ");

    e->entry.section = Entry::VARIABLE_SEC;

    dealloc(name);
    return e;
}

Node *EntryHandler::accessToFunctionDefinition(Parameters *params,
                                  bool is_protected)
{
    EntryNode *e = newEntryNode();
    e->entry.type = adaArgListToString(*params->args);
    e->entry.type.prepend("access function ");
    e->entry.type.append(" return ");
    e->entry.type.append(params->type->str);

    if (is_protected)
    {
        e->entry.type.prepend("protected ");
    }
    e->entry.section = Entry::VARIABLE_SEC;

    dealloc(params);
    return e;
}

Node *EntryHandler::accessToProcedureDefinition(Parameters *params,
                                  bool is_protected)
{
    EntryNode *e = newEntryNode();
    e->entry.type = adaArgListToString(*params->args);
    e->entry.type.prepend("access function ");

    if (is_protected)
    {
        e->entry.type.prepend("protected ");
    }
    e->entry.section = Entry::VARIABLE_SEC;

    dealloc(params);
    return e;
}
/*===================== Code Handler ========================== */
CodeHandler::CodeHandler(CodeNode *root): RuleHandler(root) {}
CodeHandler::~CodeHandler(){}

Node* CodeHandler::packageSpec(Node *base, Node* doc)
{
  return base;
}
Node* CodeHandler::packageSpecBase(
         const char* name,
          Nodes *publics,
          Nodes *privates)
{
  CodeNode *pkg = newCodeNode(ADA_PKG, name, "");
  if(publics)
  {
    addObjRefsToParent(pkg, publics);
    moveUnderNode(pkg, publics);
  }
  if (privates)
  {
    addObjRefsToParent(pkg, privates);
    moveUnderNode(pkg, privates);
  }
  return pkg;
}

Node* CodeHandler::subprogramSpec(Node *base, Node* doc)
{
  return base;
}

Node* CodeHandler::subprogramSpecBase(QCString *name,
                        Parameters *params)
{
  /* TODO handle type */
  CodeNode *fun = newCodeNode(ADA_SUBPROG, *name, "");
  if (params)
  {
    fun->appendRefs(params->refs);
    dealloc(params);
  }

  return fun;
}

Node* CodeHandler::subprogramBody(Node *base, 
                                  Nodes *decls,
                                  Identifiers *refs)
{
  if (decls)
  {
    addObjRefsToParent(base, decls);
    moveUnderNode(base, decls);
  }

  if (refs)
  {
    CodeNode *base_code = dynamic_cast<CodeNode*>(base);
    base_code->appendRefs(*refs);
    dealloc(refs);
  }
  return base;
}

Node* CodeHandler::packageBodyBase(
          const char* name,
          Nodes *decls,
          Identifiers *refs)
{
  CodeNode *pkg = newCodeNode(ADA_PKG, name, "");

  if (decls)
  {
    addObjRefsToParent(pkg, decls);
    moveUnderNode(pkg, decls);
  }

  if (refs)
    pkg->appendRefs(*refs);
    dealloc(refs);
  return pkg;
}

Node* CodeHandler::packageBody(Node *base, Node* doc)
{
    return base;
}

Nodes *CodeHandler::objDecl(Nodes *base, Node *doc)
{
  return base;
}
Nodes *CodeHandler::objDeclBase(Identifiers *ids, Expression *type,
                                Expression *expr)
{
  Nodes* nodes = new Nodes;
  CodeNode* n;

  IdentifiersIter it = ids->begin();
  for (;it != ids->end();++it)
  {
    /* TODO ADD TYPE */
    n = newCodeNode(ADA_VAR, it->str, "");
    if (expr)
    {
      n->refs.splice(n->refs.begin(), expr->ids);
    }
    nodes->push_back(n);
  }

  if (expr)
      dealloc(expr);
  return nodes;
}

Node* CodeHandler::full_type_declaration(char *id, Node *def)
{
    if (def){
        CodeNode *c_def = dynamic_cast<CodeNode*>(def);
        c_def->name = id;
    }
    dealloc(id);

    return def;
}
Nodes* CodeHandler::full_type_declarations(char *id, Nodes *defs)
{
    CodeNode *c = newCodeNode(ADA_ENUM, id, "");
    
    NodesIter nit = defs->begin();
    Node *n;
    for(;nit != defs->end();++nit)
    {
      n = *nit;
      //c->addChild(n->clone());
    }

    defs->push_front(c);
    dealloc(id);
    return defs;
}

Nodes *CodeHandler::enumeration_type_definition(Identifiers *ids)
{
  Nodes *nodes = new Nodes;

  IdentifiersIter it = ids->begin();
  for (;it != ids->end(); ++it)
  {
    CodeNode *c = newCodeNode(ADA_ENUM, it->str, "");
    nodes->push_front(c);
  }

  return nodes;
}

Node *CodeHandler::record_definition(Nodes *members)
{
   CodeNode* rd = newCodeNode(ADA_RECORD, "", "");
   moveUnderNode(rd, members);
   return rd;
}

Node *CodeHandler::record_definition()
{
   CodeNode* rd = newCodeNode(ADA_RECORD, "", "");
   return rd;
}

Nodes *CodeHandler::component_declaration(Identifiers *ids, Expression *type,
                             Expression *expr)
{
  Nodes* nodes = new Nodes;
  CodeNode* n;

  IdentifiersIter it = ids->begin();
  for (;it != ids->end();++it)
  {
    /* TODO ADD TYPE */
    n = newCodeNode(ADA_VAR, it->str, "");
    if (expr)
    {
      n->refs.splice(n->refs.begin(), expr->ids);
    }
    nodes->push_back(n);
  }

  if (expr)
      dealloc(expr);
  return nodes;
}

CodeNode *CodeHandler::newCodeNode(
    NodeType type,
    const QCString &name, const QCString &name_space)
{
  return new CodeNode(type, name, name_space);
}

Node* CodeHandler::type_definition(Expression *def)
{
  CodeNode *c = new CodeNode(ADA_VAR, "", "");
  c->appendRefs(def->ids);
  dealloc(def);
  return c;
}

Node *CodeHandler::accessToObjectDefinition(Expression *name,
                                        QCString *access_mod)
{
  CodeNode *c = new CodeNode(ADA_VAR, "", "");
  c->appendRefs(name->ids);
  dealloc(name);
  return c;
}

Node *CodeHandler::accessToFunctionDefinition(Parameters *params,
                                  bool is_protected)
{
  CodeNode *c = new CodeNode(ADA_SUBPROG, "", "");
  c->appendRefs(params->refs);
  c->appendRefs(params->type->ids);
  dealloc(params);
  return c;
}

Node *CodeHandler::accessToProcedureDefinition(Parameters *params,
                                  bool is_protected)
{
  CodeNode *c = new CodeNode(ADA_SUBPROG, "", "");
  c->appendRefs(params->refs);
  dealloc(params);
  return c;
}
