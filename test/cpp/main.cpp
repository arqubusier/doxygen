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

/**
 * \brief global variable.
 *
 * asdfsdfsdf
 */
int glob2;

class abst{
public:
   virtual void fun() = 0;
  void priv(){;}
  int m;
};

class con1:protected abstr{
public:
  void fun(){;}
private:
  void priv(){;}
  int m1;
};

class con2:public abstr{
public:
  void fun(){;}
private:
  void priv(){;}
  void priv(){;}
  int m2;
};

class con3:public con1{
public:
  void fun(){;}
private:
  void priv(){;}
  void priv(){;}
  int m3;
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
