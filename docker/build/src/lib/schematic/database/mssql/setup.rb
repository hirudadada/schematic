# frozen_string_literal: true

module Schematic
  module Database
    module MSSQL
      class Setup < Database::Setup
        class << self
          def ensure_job_history_table(client)
            return unless client&.run

            client.run(<<~SQL)
              IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[job_history]') AND type in (N'U'))
              BEGIN
                CREATE TABLE [dbo].[job_history] (
                  [id] INT IDENTITY(1,1) PRIMARY KEY,
                  [job_name] VARCHAR(255) NOT NULL,
                  [start_time] DATETIME NOT NULL,
                  [end_time] DATETIME,
                  [status] VARCHAR(50)
                )
              END
            SQL
          end
        end
      end
    end
  end
end 
