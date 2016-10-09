--! \file ada_test_package.adb
--! \brief The ada.adb file.
--!
--! A package for testing the doxygen Ada Parser.
--
--! \package Ada_Test_Package namespace
--! 
--! \brief ethuoetnuhnht.
--!
--! oetnuhnoteuh

with Ada.Text_IO;
use Ada.Text_IO;

--! \brief ada_test_package package.
--!
--! detailed.
package body Ada_Test_Package is
    --! \brief nested_package definition.
    --!
    --! more text.
    package body nested_package is

        --! \brief test function.
        procedure test is
        begin
          Put_Line("Nested package");
        end test;
    begin
        test;
    end nested_package;

    --! \brief Test functions.
    --!
    --! more text.
    function function_test(
        x, y: in Integer:=pub;
        z: in float) return Integer is
    begin
        --Put_line("function_test");
        procedure_test(f=>z, int1=>y, int2=>x);
        return 1;
    end function_test;

    --! \brief Test procedures.
    --!
    --! more text.
    procedure procedure_test(
        int1, int2: in Integer;
        f: in Float) is
    begin
        Put_line("procedure_test");

        Put( "f =" );
        Put( Float'Image(f) );
        Put( ", int1 = " );
        Put( Integer'Image(int1));
        Put( ", int2 = " );
        Put( Integer'Image(int2));
        New_Line(1);
    end procedure_test;

    --! \brief Test expressions.
    procedure expressions is
        x, y, z: Integer;
        u, v, w: Integer:= 1;
    begin
      --x:= y * z;
      null;
    end expressions;

    --! \brief Test compounds.
    procedure compounds(X:in integer) is
        Temperature: float:= 40.0;
    begin
        if Temperature >= 40.0 then
                Put_Line ("Wow!");
                Put_Line ("It is extremely hot");
        elsif Temperature >= 30.0 then
                Put_Line ("It is hot");
        elsif Temperature >= 20.0 then
                Put_Line ("It is warm");
        else
                Put_Line ("It is freezing");
                if True then
                    Put_line("Hej");
                end if;
        end if; 

        case X is
           when 1 =>
              Walk_The_Dog;
           when 5 =>
              Launch_Nuke;
           when 8 | 10 =>
              Sell_All_Stock;
           when others =>
              Self_Destruct;
        end case;

        While_Loop :
            while X >= 5 loop
                null;
            end loop While_Loop;

        For_Loop:
         for I in 1 .. 10 loop
             null;
         end loop For_Loop;

       Array_Loop :
         for I in Character'Range loop
            null;
         end loop Array_Loop;
    end compounds;

    --! \brief Dummy function 1.
    procedure Walk_The_Dog is begin Put_Line("Walk_The_dog"); end;
    --! \brief Dummy function 2.
    procedure Launch_Nuke is begin null; end;
    --! \brief Dummy function 3.
    procedure Sell_All_Stock is begin null; end;
    --! \brief Dummy function 4.
    procedure Self_Destruct is begin null; end;
begin
    null;
end Ada_Test_Package;
