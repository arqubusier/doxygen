/** \file adacommon.cpp
 * \brief Definines some declarations from adaparser.h.
 *
 * Has defintions for EntryNode, CodeNode, and Identifier.*/
#include "adaparser.h"
#include "message.h"
#include "dbg_util.h"


void initEntry (Entry &e, Entry *parent, Protection prot,
                MethodTypes mtype, bool stat,
                Specifier virt)
{
  e.protection = prot;
  e.mtype      = mtype;
  e.virt       = virt;
  e.stat       = stat;
  e.lang       = SrcLangExt_Ada; 
  e.setParent(parent);
}

/* ==================== EntryNode =====================*/
EntryNode::EntryNode(): entry(*(new Entry))
{
  initEntry(entry);
}

EntryNode::EntryNode(Entry &entryRef):entry(entryRef){}

void EntryNode::addChild(Node *child)
{
  EntryNode *en = dynamic_cast<EntryNode*> (child);
  this->entry.addSubEntry(&en->entry);
}

void EntryNode::print()
{
  this->entry.printTree();
}

/* ==================== CodeNode =====================*/
void CodeNode::addChild(Node *child)
{
  CodeNode *cn = dynamic_cast<CodeNode*> (child);
  children.push_back(cn);
}

void CodeNode::print()
{
  this->print_("");
}
void CodeNode::print_(std::string pad)
{
  msg("%s====================\n", pad.data());
  msg("%sNODE:\n", pad.data());
  msg("%ssection: %d\n", pad.data(), type); 
  printQC(pad, "name", name);
  printQC(pad, "namespace", name_space.data());

  msg("%sREFS:\n", pad.data());
  printIds(&refs, pad);

  msg("%sCHILDREN:\n", pad.data());
  pad +=  "    "; 
  CodeNodesIter it = children.begin();
  for (; it!=children.end(); ++it)
  {
    (*it)->print_(pad);
  }
  
}

CodeNode::CodeNode(
    NodeType type_,
    const QCString &name_, const QCString &name_space_)
      :type(type_), name(name_), name_space(name_space_)
{}


void CodeNode::appendRefs(Identifiers *new_refs)
{
  if (new_refs)
  {
    refs.splice(refs.begin(), *new_refs);
    dealloc(new_refs);
  }
}

CodeNode::CodeNode():type(ADA_UNKNOWN), name(""), name_space("") {}

/*====================== Identifer ================ */
void Identifier::print(std::string pad)
{
  msg("CCCCccc\n");
  msg("%s%s @ l%d,c%d\n", pad.data(), str.data(), line, col); 
}
Identifier::Identifier(QCString str_, int line_, int col_)
      :str(str_), line(line_), col(col_){}
Identifier::Identifier(QCString str_):str(str_), line(-1), col(-1){}

Expression::Expression(QCString str_):str(str_){}
Expression::Expression(QCString str_, Identifier id):
    str(str_),ids(1, id){}

/* =================== Misc ======================= */
void printIds(Identifiers *ids, std::string pad)
{
  if(ids && !ids->empty())
  {
    printf("PRINTING NODES\n");
    printf("START\n");
    IdentifiersIter it = ids->begin();
    for (;it != ids->end();++it)
    {
      it->print(pad);
    }
    printf("END\n");
  }
  else
    printf("Identifiers empty\n");
}

