#include "adaparser.h"
/** \file adarulehandler.h
 *
 * \brief defines classes that handle rules in the ada grammar.
 * Unless noted, each handler method is used in the grammar
 * rule with the same name, but in underscare_case instead 
 * of camelCase.*/

/** \brief Abstract class declaring methods used by the
 * rules in the grammar.
 * 
 * The Ada parser uses one of multiple rulehandler derivative
 * object to build the AST. The reason for this is that the
 * Ada parser uses one set of grammar rules despite doxygen
 * expecting multiple different parsers
 * (a 'scanner', and a 'code parser').
 * The methods operate on Node objects. Derivatives of this
 * class can use derivatives of Node objects.
 */
class RuleHandler
{
public:
  void addToRoot(Node* child);
  /* debug printing */
  void printRoot(){/*m_root->print()*/;}

  RuleHandler(Node *root);
  virtual ~RuleHandler();

  /* Handler methods.*/
  virtual Node* packageSpec(Node *base, Node* doc=NULL) = 0;
  virtual Node* packageSpecBase(
            QCString* name,
            Nodes *publics=NULL,
            Nodes *privates=NULL) = 0;
  virtual Node* subprogramSpec(Node *base, Node* doc=NULL) = 0;
  virtual Node* subprogramSpecBase(QCString* name,
                          Parameters *params=NULL) = 0;
  virtual Node* subprogramBody(Node *base, 
                               Nodes *decls=NULL,
                               Identifiers *refs=NULL) = 0;
  virtual Node* packageBody(Node *base, Node* doc=NULL) = 0;
  virtual Node* packageBodyBase(
            char* name,
            Nodes *decls=NULL, Identifiers *refs=NULL) = 0;
  virtual Nodes *objDecl(Nodes *base, Node *doc=NULL) = 0;
  virtual Nodes *objDeclBase(char *id, Expression *type,
                             Expression *expr=NULL, QCString *obj_mod=NULL) = 0;
  virtual Nodes *objDeclBase(char *id,
                             Identifiers *ids, Expression *type,
                             Expression *expr=NULL, QCString *obj_mod=NULL) = 0;
  virtual Node* addDoc(Node *base, Node* doc=NULL) = 0;
  virtual Nodes* addDocs(Nodes *base, Node* doc=NULL) = 0;
  virtual Node* type_definition(Expression *def) = 0;
  virtual Node* full_type_declaration(char *id, Node *def) = 0;
  virtual Nodes* full_type_declarations(char *id, Nodes *defs) = 0;
  virtual Node *accessToObjectDefinition(Expression *name,
                                        QCString *access_mod=NULL) = 0;
  virtual Node *accessToFunctionDefinition(Parameters *params,
                                            bool is_protected=false) = 0;
  virtual Node *accessToProcedureDefinition(Parameters *params,
                                            bool is_protected=false) = 0;
  virtual Nodes *enumeration_type_definition(Identifiers *ids) = 0;
  virtual Node *record_definition(Nodes *members) = 0;
  virtual Node *record_definition() = 0;
  virtual Nodes *component_list(Nodes* item, Nodes* items);
  virtual Nodes *component_list();
  virtual Nodes *component_declaration(Identifiers *ids, Expression *type,
                             Expression *expr=NULL) = 0;
  /** \brief Used in the rules decls and basic_decls. */
  virtual Nodes *declsBase(Node *new_entry);
  /** \brief Used in the rules decls and basic_decls. */
  virtual Nodes *declsBase(Nodes *new_entries);
  /** \brief Used in the rules decls and basic_decls. */
  virtual Nodes *decls(Nodes *nodes, Node *new_node);
  /** \brief Used in the rules decls and basic_decls. */
  virtual Nodes *decls(Nodes *nodes, Nodes *new_nodes);

  /* \brief handle params rule, does not need defintion by deriving class.
   */
  Parameters *params(Parameters *params, Parameters *new_params);
  /* \brief handle param_spec rule, does not need defintion by deriving class.
   */
  Parameters *paramSpec(Identifiers *ids,
                              Expression *type,
                              QCString *mode=NULL,
                              Expression *defval=NULL);
  /**
   * \brief Takes the children from src and adds them to dst.
   *
   * src parent is deallocated.
   */
  virtual void moveNodes(Nodes* dst, Nodes *src);
  /**
   * \brief Add nodes as children of a node.
   *
   * src is deallocated.
   */
  virtual void moveUnderNode(Node *dst, Nodes *src);

private:
  Node *m_root;
};

/* \brief A class with handlers for the 'normal' (scanner) parsing.
 *
 * Generates an AST of Entry objects.*/
class EntryHandler: public RuleHandler
{
public:

  EntryHandler(EntryNode *root);
  EntryHandler(Entry *root);
  ~EntryHandler();

  void addFileSection(const char *fileName);

  //handlers
  virtual Node* packageSpec(Node *base, Node* doc=NULL)
  {
    addDocToEntry(doc, base);
    return base;
  }
  virtual Node* packageSpecBase(
            QCString* name,
            Nodes *publics=NULL,
            Nodes *privates=NULL);
  virtual Node* subprogramSpec(Node *base, Node* doc=NULL)
  {
    addDocToEntry(doc, base);
    return base;
  }
  virtual Node* subprogramSpecBase(QCString* name,
                          Parameters *params=NULL);
  virtual Node* packageBody(Node *base, Node* doc=NULL)
  {
    addDocToEntry(doc, base);
    return base;
  }
  virtual Node* packageBodyBase(
            char* name,
            Nodes *decls=NULL,
            Identifiers *refs=NULL);
  virtual Node* subprogramBody(Node *base,
                               Nodes *decls=NULL,
                               Identifiers *refs=NULL);
  virtual Nodes *objDecl(Nodes *base, Node *doc=NULL)
  {
    addDocToEntries(doc, base);
    return base;
  }
  virtual Node* addDoc(Node *base, Node* doc=NULL){
    addDocToEntry(doc, base);
    return base;
  }
  virtual Nodes* addDocs(Nodes *bases, Node* doc=NULL){
    addDocToEntries(doc, bases);
    return bases;
  }
  virtual Node* type_definition(Expression *def);
  virtual Node* full_type_declaration(char *id, Node *def);
  virtual Nodes* full_type_declarations(char *id, Nodes *defs);
  virtual Nodes *enumeration_type_definition(Identifiers *ids);
  virtual Node *record_definition(Nodes *members);
  virtual Node *record_definition();
  virtual Nodes *component_declaration(Identifiers *ids, Expression *type,
                             Expression *expr=NULL);
  virtual Nodes *objDeclBase(char *id, Expression *type,
                             Expression *expr=NULL, QCString *obj_mod=NULL);
  virtual Nodes *objDeclBase(char *id,
                             Identifiers *ids, Expression *type,
                             Expression *expr=NULL, QCString *obj_mod=NULL);

  virtual Node *accessToObjectDefinition(Expression *name,
                                        QCString *access_mod=NULL);
  virtual Node *accessToFunctionDefinition(Parameters *params,
                                            bool is_protected=false);
  virtual Node *accessToProcedureDefinition(Parameters *params,
                                            bool is_protected=false);
private:
  void addDocToEntry(Node *doc, Node *base);
  void addDocToEntries(Node *doc, Nodes *base);
  EntryNode *newEntryNode();
};

/* \brief A class with handlers for (code) parsing.
 *
 * Generates an AST of CodeNode objects. Responsible
 * for creating links between Entries.
 * TODO: 2016-08-11 syntax highligting not implemented*/
void addObjRefsToParent(Node* parent, Nodes* decls);

class CodeHandler: public RuleHandler
{
public:
  CodeHandler(CodeNode *root);
  ~CodeHandler();

  CodeNode *newCodeNode(
    NodeType type,
    const QCString &name, const QCString &name_space);

  //handlers
  virtual Node* packageSpec(Node *base, Node* doc=NULL);
  virtual Node* packageSpecBase(
            QCString* name,
            Nodes *publics=NULL,
            Nodes *privates=NULL);
  virtual Node* subprogramSpec(Node *base, Node* doc=NULL);
  virtual Node* subprogramSpecBase(QCString* name,
                          Parameters *params=NULL);
  virtual Node* subprogramBody(Node *base,
                               Nodes *decls=NULL,
                               Identifiers *ids=NULL);
  virtual Node* packageBody(Node *base, Node* doc=NULL);
  virtual Node* packageBodyBase(
            char* name,
            Nodes *decls=NULL,
            Identifiers *ids=NULL);
  virtual Nodes *objDecl(Nodes *base, Node *doc=NULL);
  virtual Nodes *objDeclBase(char *id, Expression *type,
                             Expression *expr=NULL, QCString *obj_mod=NULL);
  virtual Nodes *objDeclBase(char *id,
                             Identifiers *ids, Expression *type,
                             Expression *expr=NULL, QCString *obj_mod=NULL);
  virtual Node* addDoc(Node *base, Node* doc=NULL)
  {
        return base;
  }
  virtual Nodes* addDocs(Nodes *bases, Node* doc=NULL)
  {
        return bases;
  }
  virtual Node* full_type_declaration(char *id, Node *def);
  virtual Nodes* full_type_declarations(char *id, Nodes *defs);
  virtual Nodes *enumeration_type_definition(Identifiers *ids);
  virtual Node *record_definition(Nodes *members);
  virtual Node *record_definition();
  virtual Nodes *component_declaration(Identifiers *ids, Expression *type,
                             Expression *expr=NULL);
  virtual Node* type_definition(Expression *def);
  virtual Node *accessToObjectDefinition(Expression *name,
                                        QCString *access_mod=NULL);
  virtual Node *accessToFunctionDefinition(Parameters *params,
                                            bool is_protected=false);
  virtual Node *accessToProcedureDefinition(Parameters *params,
                                            bool is_protected=false);
};
