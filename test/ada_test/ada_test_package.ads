--! \file ada_test_package.ads
--! \brief A package for testing the doxygen Ada Parser.
--!
--! Tests various ada and doxygen syntax.
package Ada_Test_Package is
    --! a public variable.
    pub: Integer:=1337;

    --! \brief Test nested_packages.
    package nested_package is
      procedure test;
    end nested_package;

    --! \brief Test functions.
    function function_test(
        x, y: in Integer :=pub;
        z: in float) return Integer;
    --! \brief Test procedures.
    procedure procedure_test(
        f: in Float;
        int1, int2: in Integer);

    --! \brief Test expressions.
    procedure expressions;
    --! \brief Test compounds.
    procedure compounds(X:in Integer);
    --! \brief Dummy function 1.
    procedure Walk_The_Dog;
    --! \brief Dummy function 2.
    procedure Launch_Nuke;
    --! \brief Dummy function 3.
    procedure Sell_All_Stock;
    --! \brief Dummy function 4.
    procedure Self_Destruct;

private
    --! a private variable.
    priv: Integer:=77;

end Ada_Test_Package;
