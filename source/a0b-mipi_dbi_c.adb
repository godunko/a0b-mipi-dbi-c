--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.Awaits;
with A0B.Callbacks.Generic_Non_Dispatching;

package body A0B.MIPI_DBI_C is

   procedure On_Finished (Self : in out MIPI_DBI_C_4_Line'Class);

   package On_Finished_Callbacks is
     new A0B.Callbacks.Generic_Non_Dispatching
           (MIPI_DBI_C_4_Line, On_Finished);

   -------------
   -- Command --
   -------------

   procedure Command
     (Self     : in out MIPI_DBI_C_4_Line'Class;
      Command  : Command_Code;
      Finished : A0B.Callbacks.Callback;
      Success  : in out Boolean) is
   begin
      Self.State             := Done;
      Self.Finished_Callback := Finished;

      Self.Command_Buffer (0) := A0B.Types.Unsigned_8 (Command);
      Self.Command_Descriptor.Buffer := Self.Command_Buffer'Address;
      Self.Command_Descriptor.Length := 1;

      Self.SPI.Select_Device (Success);

      Self.D_CX.Set (False);
      Self.SPI.Transmit
        (Self.Command_Descriptor'Unchecked_Access,
         On_Finished_Callbacks.Create_Callback (Self),
         Success);
   end Command;

   ------------------
   -- Command_Read --
   ------------------

   procedure Command_Read
     (Self    : in out MIPI_DBI_C_4_Line'Class;
      Command : Command_Code;
      Data    : in out A0B.Types.Arrays.Unsigned_8_Array;
      --  Data    : not null Unsigned_8_Array_Variable_Access;
      --  Finished : A0B.Callbacks.Callback;
      Success : in out Boolean)
   is
      Await : aliased A0B.Awaits.Await;

   begin
      Self.Command_Buffer (0) := A0B.Types.Unsigned_8 (Command);
      Self.Command_Descriptor.Buffer := Self.Command_Buffer'Address;
      Self.Command_Descriptor.Length := 1;

      Self.SPI.Select_Device (Success);
      Self.D_CX.Set (False);
      Self.SPI.Transmit
        (Self.Command_Descriptor'Unchecked_Access,
         A0B.Awaits.Create_Callback (Await),
         Success);
      A0B.Awaits.Suspend_Until_Callback (Await, Success);
      Self.D_CX.Set (True);

      Self.Data_Descriptor.Buffer := Data'Address;
      Self.Data_Descriptor.Length := Data'Length;
      Self.SPI.Receive
        (Self.Data_Descriptor'Unchecked_Access,
         A0B.Awaits.Create_Callback (Await),
         Success);
      A0B.Awaits.Suspend_Until_Callback (Await, Success);

      Self.SPI.Release_Device;
   end Command_Read;

   -------------------
   -- Command_Write --
   -------------------

   procedure Command_Write
     (Self     : in out MIPI_DBI_C_4_Line'Class;
      Command  : Command_Code;
      Data     : not null Unsigned_8_Array_Constant_Access;
      Finished : A0B.Callbacks.Callback;
      Success  : in out Boolean) is
   begin
      Self.Finished_Callback := Finished;
      Self.State             := Write;

      Self.Command_Buffer (0)        := A0B.Types.Unsigned_8 (Command);
      Self.Command_Descriptor.Buffer := Self.Command_Buffer'Address;
      Self.Command_Descriptor.Length := 1;
      Self.Data_Descriptor.Buffer    := Data.all'Address;
      Self.Data_Descriptor.Length    := Data'Length;

      Self.SPI.Select_Device (Success);
      Self.D_CX.Set (False);
      Self.SPI.Transmit
        (Self.Command_Descriptor'Unchecked_Access,
         On_Finished_Callbacks.Create_Callback (Self),
         Success);
   end Command_Write;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize (Self : in out MIPI_DBI_C_4_Line'Class) is
   begin
      Self.State := Initial;
      Self.D_CX.Set (True);
   end Initialize;

   -----------------
   -- On_Finished --
   -----------------

   procedure On_Finished (Self : in out MIPI_DBI_C_4_Line'Class) is
      Success : Boolean := True;

   begin
      Self.D_CX.Set (True);

      case Self.State is
         when Initial =>
            raise Program_Error;

         when Write =>
            Self.State := Done;
            Self.SPI.Transmit
              (Self.Data_Descriptor'Unchecked_Access,
               On_Finished_Callbacks.Create_Callback (Self),
               Success);

            if not Success then
               raise Program_Error;
            end if;

         when Done =>
            Self.State := Initial;
            Self.SPI.Release_Device;
            A0B.Callbacks.Emit_Once (Self.Finished_Callback);
      end case;
   end On_Finished;

end A0B.MIPI_DBI_C;
