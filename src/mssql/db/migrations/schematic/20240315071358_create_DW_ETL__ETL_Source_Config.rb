# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(Sequel.qualify(:DW_ETL_LOG, :ETL_Source_Configs)) do
      primary_key :TableID
      String :Source_System
      String :Source_DB
      String :Source_Schema
      String :Source_Table
      String :Target_DB
      String :Target_Schema
      String :Target_Table
      String :Key_Mapping
      Integer :Batch_NoofRcds
      String :EntryType_to_ModLog
      DateTime :Max_Process_datetime
      String :Target_ModLog
      String :Last_Modified
      String :Remove_Journal
      String :Verification_exclude
      String :Verification_Source_Rename
      String :Target_Remove_Delete
      Integer :Parsing_interval_ms

      unique [:Source_System, :Source_DB, :Source_Schema, :Source_Table, :Target_DB, :Target_Schema, :Target_Table], :name=>:UK
    end
  end
end
