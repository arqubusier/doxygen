#include "adaparser.h"

/* handler */


class RuleHandler
{
public:
  void addToRoot(Node* child);
  void printRoot(){m_root->print();}

  RuleHandler(Node *root);
  virtual ~RuleHandler();

  //handlers
  virtual Node* packageSpec(Node *base, Node* doc=NULL) = 0;
  virtual Node* packageSpecBase(
            const char* name,
            Nodes *publics=NULL,
            Nodes *privates=NULL) = 0;
  virtual Node* subprogramSpec(Node *base, Node* doc=NULL) = 0;
  virtual Node* subprogramSpecBase(const char* name,
                          Parameters *params=NULL, const char *type=NULL) = 0;
  virtual Node* subprogramBody(Node *base, 
                               Nodes *decls=NULL,
                               Identifiers *refs=NULL) = 0;
  virtual Node* packageBody(Node *base, Node* doc=NULL) = 0;
  virtual Node* packageBodyBase(
            const char* name,
            Nodes *decls=NULL, Identifiers *refs=NULL) = 0;
  virtual Nodes *declsBase(Node *new_entry);
  virtual Nodes *declsBase(Nodes *new_entries);
  virtual Nodes *decls(Nodes *nodes, Node *new_node);
  virtual Nodes *decls(Nodes *nodes, Nodes *new_nodes);
  virtual Nodes *objDecl(Nodes *base, Node *doc=NULL) = 0;
  virtual Nodes *objDeclBase(Identifiers *ids, Expression *type,
                             Expression *expr=NULL) = 0;
  Parameters *params(Parameters *params, Parameters *new_params);
  Parameters *paramSpec(Identifiers *ids,
                              QCString *type,
                              QCString *mode=NULL,
                              Expression *defval=NULL);
  /**
   * Takes the children from src and adds them to dst.
   * dst parent is removed.
   */
  virtual void moveNodes(Nodes* dst, Nodes *src);
  /**
   * \brief Add nodes as children of a node.
   */
  virtual void moveUnderNode(Node *dst, Nodes *src);

private:
  Node *m_root;
};

/* entry handler */
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
            const char* name,
            Nodes *publics=NULL,
            Nodes *privates=NULL);
  virtual Node* subprogramSpec(Node *base, Node* doc=NULL)
  {
    addDocToEntry(doc, base);
    return base;
  }
  virtual Node* subprogramSpecBase(const char* name,
                          Parameters *params=NULL, const char *type=NULL);
  virtual Node* packageBody(Node *base, Node* doc=NULL)
  {
    addDocToEntry(doc, base);
    return base;
  }
  virtual Node* packageBodyBase(
            const char* name,
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
  virtual Nodes *objDeclBase(Identifiers *ids, Expression *type,
                             Expression *expr=NULL);
private:
  void addDocToEntry(Node *doc, Node *base);
  void addDocToEntries(Node *doc, Nodes *base);
  EntryNode *newEntryNode();
};

/* code handler */
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
            const char* name,
            Nodes *publics=NULL,
            Nodes *privates=NULL);
  virtual Node* subprogramSpec(Node *base, Node* doc=NULL);
  virtual Node* subprogramSpecBase(const char* name,
                          Parameters *params=NULL, const char *type=NULL);
  virtual Node* subprogramBody(Node *base,
                               Nodes *decls=NULL,
                               Identifiers *ids=NULL);
  virtual Node* packageBody(Node *base, Node* doc=NULL);
  virtual Node* packageBodyBase(
            const char* name,
            Nodes *decls=NULL,
            Identifiers *ids=NULL);
  virtual Nodes *objDecl(Nodes *base, Node *doc=NULL);
  virtual Nodes *objDeclBase(Identifiers *ids, Expression *type,
                             Expression *expr=NULL);
};
