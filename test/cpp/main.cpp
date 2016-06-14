/* \file main.cpp
 *
 * \brief qwerty.
 *
 * asdfsdfsdf
 */
#include "f2.h"
#include "f3.h"

/**
 * \brief global variable.
 *
 * asdfsdfsdf
 */
float glob;

class abst{
public:
   virtual void fun() = 0;
};

class con1:protected abstr{
pulblic:
  void fun(){;}
private:
  void priv(){;}
};

class con2:public abstr{
public:
  void fun(){;}
private:
  void priv(){;}
};

class con3:public con1{
public:
  void fun(){;}
private:
  void priv(){;}
};


/** \brief main.
 *
 * asdfsdf
 */
int main(){
    func2();
    func3();
    return 0;
}
