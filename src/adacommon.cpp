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
  refs.splice(refs.begin(), *new_refs);
  delete new_refs;
}

CodeNode::CodeNode():type(ADA_UNKNOWN), name(""), name_space("") {}
/* =================== Misc ======================= */
QCString adaArgListToString(const ArgumentList &args)
{
  QCString res = "()";
  if (args.isEmpty())
    return res;
  res = "(";

  Argument *arg;
  ArgumentListIterator it(args);
  it.toFirst();
  arg=it.current();
  res += arg->name;
  res += " ";
  QCString prev_type = arg->type;
  QCString defval = "";
  ++it;
  
  for (; (arg=it.current()); ++it )
  {
    QCString type = arg->type;
    defval = arg->defval;
    if (type == prev_type) 
    {
      res += ", ";
      res += arg->name;
    }
    else 
    {
      res += ": ";
      res += prev_type;
      res += " := ";
      res += defval;
      res += ";\n";
      res += arg->name;
      prev_type = type;
    }
  }
  res += ": ";
  res += prev_type;
  res += " := ";
  res += defval;
  res += ")";

}
