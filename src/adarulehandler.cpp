#include <stdio.h>
#include "adarulehandler.h"
#include "adaparser.h"
#include "arguments.h"
#include "types.h"
#include "util.h"

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
  delete src;
}

void RuleHandler::moveUnderNode(Node *node, Nodes *nodes)
{
  NodesIter it;
  for (it=nodes->begin(); it!=nodes->end(); ++it)
  {
    node->addChild(*it);
  } 
  delete nodes;
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
    params->refs->splice(params->refs->begin(), *(new_params->refs));
  }
  else
      params = new Parameters;

  if (!params->refs->empty())
  {
    printf("BBBBBBBBBBBBBB\n");
    params->refs->front().print();
  }

  if (!new_params->refs->empty())
  {
    printf("BBBBBBBBBBBBBB\n");
    new_params->refs->front().print();
  }

  return params;
}

Parameters *RuleHandler::paramSpec(Identifiers *ids,
                              QCString *type,
                              QCString *mode,
                              Expression *defval)
{
  Parameters *params = new Parameters;

  IdentifiersIter it = ids->begin();
  for (; it != ids->end(); ++it)
  {
    Argument *a = new Argument;
    if (mode)
      a->type = *mode;
    a->type += " " + *type;
    a->name = (it->str);
    a->defval = "";
    if (defval)
      a->defval = defval->str;
    params->args->append(a);
  }
  delete type;
  if (mode)
    delete mode;

  if (defval)
  {
    printf("AAAAAAAAAAAAAAAA\n");
    params->refs->splice(params->refs->begin(), defval->ids);
    params->refs->front().print();
    delete defval;
  }

  return params;
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


  delete name; 
  return pkg; 
} 


Node* EntryHandler::subprogramSpecBase(const char* name,
                        Parameters *params, const char *type)
{
  EntryNode *fun = newEntryNode();
  fun->entry.name = name;
  delete name;

  if (params)
  {
    fun->entry.argList = params->args;
    fun->entry.args = adaArgListToString(*(params->args));
    delete params;
  }
  if (type)
  {
    fun->entry.type = type;
    delete type;
  }
  fun->entry.section = Entry::FUNCTION_SEC;
  return fun;
}

Node* EntryHandler::subprogramBody(Node *base,
                                   Nodes *decls,
                                   Identifiers *refs)
{
  if (refs)
  {
    printf("function refs\n");
    IdentifiersIter it = refs->begin();
    for (;it != refs->end(); ++it)
    {
        it->print();
    }
  }
  return base;
}

Nodes *EntryHandler::objDeclBase(Identifiers *refs, QCString *type,
                                 Expression *expr)
{
  Nodes *nodes = new Nodes;

  IdentifiersIter it = refs->begin();
  for (;it != refs->end(); ++it)
  {
    EntryNode *e = newEntryNode();
    e->entry.name = it->str;
    e->entry.type = *type;
    e->entry.section = Entry::VARIABLE_SEC;
    nodes->push_front(e);
  }

  if (expr)
  {
    printf("default value %s\n", expr->str.data());
    delete expr;
  }

  delete type;
  delete refs;
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
  
  if (ids)
  {
    printf("package refs\n");
    IdentifiersIter it = ids->begin();
    for (;it != ids->end(); ++it)
    {
      it->print();
    }
  }

  delete ids;
  delete name;
  
  return pkg;
}

EntryNode* EntryHandler::newEntryNode()
{
    EntryNode* e = new EntryNode;
    initEntry(e->entry);
    return e;
}

void EntryHandler::addDocToEntry(Node *doc, Node *entry){
  if( doc ){
    printf("before doc\n");
    EntryNode *e_doc = dynamic_cast<EntryNode*>(doc);
    printf("before entry\n");
    EntryNode *e_entry = dynamic_cast<EntryNode*>(entry);
    printf("after\n");
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
  printf("a\n");
  moveUnderNode(pkg, publics);
  if (privates)
  {
    printf("b\n");
    moveUnderNode(pkg, privates);
  }
    printf("c\n");
  return pkg;
}

Node* CodeHandler::subprogramSpec(Node *base, Node* doc)
{
  return base;
}
Node* CodeHandler::subprogramSpecBase(const char* name,
                        Parameters *params, const char *type)
{
  /* TODO ADD PARAMETERS AND TYPE TO NAME */
  CodeNode *fun = newCodeNode(ADA_SUBPROG, name, "");
  fun->appendRefs(params->refs);
  delete params;

  return fun;
}

Node* CodeHandler::subprogramBody(Node *base, 
                                  Nodes *decls,
                                  Identifiers *refs)
{
  if (refs)
  {
    printf("function refs\n");
    IdentifiersIter it = refs->begin();
    for (;it != refs->end(); ++it)
    {
       it->print();
    }
    CodeNode *base_code = dynamic_cast<CodeNode*>(base);
    base_code->appendRefs(refs);
  }
  return base;
}

Node* CodeHandler::packageBodyBase(
          const char* name,
          Nodes *decls,
          Identifiers *refs)
{
  CodeNode *pkg = newCodeNode(ADA_PKG, name, "");

  if (refs)
  {
    printf("package refs\n");
    IdentifiersIter it = refs->begin();
    for (;it != refs->end(); ++it)
    {
        it->print();
    }
    pkg->appendRefs(refs);
  }

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
Nodes *CodeHandler::objDeclBase(Identifiers *ids, QCString *type,
                                Expression *expr)
{
  Nodes* nodes = new Nodes;
  Node* n;

  IdentifiersIter it = ids->begin();
  for (;it != ids->end();++it)
  {
    /* TODO ADD EXPRESSION AND TYPE */
    n = newCodeNode(ADA_VAR, it->str, "");
    nodes->push_back(n);
  }

  return nodes;
}

CodeNode *CodeHandler::newCodeNode(
    NodeType type,
    const QCString &name, const QCString &name_space)
{
  return new CodeNode(type, name, name_space);
}
