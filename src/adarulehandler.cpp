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
  if (!dst)
    printf("DST EMPTY");
  if (!src)
    printf("SRC EMPTY");

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
  printf("bbbb\n");
  Nodes *es = new Nodes;
  moveNodes(es, new_nodes);
  return es;
}

Nodes *RuleHandler::decls(Nodes *nodes, Node *new_node)
{ 
  printf("cccc\n");
  nodes->push_front(new_node);
  return nodes;
}

Nodes *RuleHandler::decls(Nodes *nodes, Nodes *new_nodes)
{ 
  printf("dddd\n");
  moveNodes(nodes, new_nodes);
  printf("dddd2\n");
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
  dealloc(type);
  if (mode)
    dealloc( mode);

  if (defval)
  {
    printf("AAAAAAAAAAAAAAAA\n");
    params->refs->splice(params->refs->begin(), defval->ids);
    params->refs->front().print();
    dealloc( defval);
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


  dealloc( name);
  return pkg; 
} 


Node* EntryHandler::subprogramSpecBase(const char* name,
                        Parameters *params, const char *type)
{
  EntryNode *fun = newEntryNode();
  fun->entry.name = name;
  dealloc( name);

  if (params)
  {
    fun->entry.argList = params->args;
    fun->entry.args = adaArgListToString(*(params->args));
    dealloc( params);
  }
  if (type)
  {
    fun->entry.type = type;
    dealloc( type);
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
    dealloc( expr);
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
  
  if (ids)
  {
    printf("package refs\n");
    IdentifiersIter it = ids->begin();
    for (;it != ids->end(); ++it)
    {
      it->print();
    }
  }

  dealloc( ids);
  dealloc( name);
  
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

Node* CodeHandler::subprogramSpecBase(const char* name,
                        Parameters *params, const char *type)
{
  /* TODO handle type */
  CodeNode *fun = newCodeNode(ADA_SUBPROG, name, "");
  if (params)
  {
    fun->appendRefs(params->refs);
    dealloc( params);
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

  if (decls)
  {
    addObjRefsToParent(pkg, decls);
    moveUnderNode(pkg, decls);
  }

  if (refs)
    pkg->appendRefs(refs);

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
  CodeNode* n;

  IdentifiersIter it = ids->begin();
  for (;it != ids->end();++it)
  {
    /* TODO ADD TYPE */
    n = newCodeNode(ADA_VAR, it->str, "");
    if (expr)
      n->appendRefs(&expr->ids);
    nodes->push_back(n);
  }

  return nodes;
}

void addObjRefsToParent(Node* parent, Nodes* decls)
{
  NodesIter nit = decls->begin();
  CodeNode *parentCode = dynamic_cast<CodeNode*>(parent);
  CodeNode *cn;
  for(;nit != decls->end();++nit)
  {
    cn = dynamic_cast<CodeNode*>(*nit);
    if (cn->type == ADA_VAR && &cn->refs && !cn->refs.empty())
      parentCode->appendRefs(&cn->refs);
  }
}

CodeNode *CodeHandler::newCodeNode(
    NodeType type,
    const QCString &name, const QCString &name_space)
{
  return new CodeNode(type, name, name_space);
}
