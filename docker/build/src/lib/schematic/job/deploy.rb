require 'pathname'
require 'erb'
require 'yaml'

module Schematic
  class Job

    def create(name)
      job_template = <<~JOBTEMPLATE
        # frozen_string_literal: true
        ---
          job_name: <%= ENV['TMPL_JOB_NAME'] %>
          enabled: <%= ENV['TMPL_ENABLED'] %>
          delete_level: <%= ENV['TMPL_DELETE_LEVEL'] %>
          description: _TEMPLATE
          category_name: ETL - Data Staging
          owner_login_name: <%= ENV['TMPL_OWNER_LOGIN_NAME'] %>
          schedule_name: _Hourly_Schedule_
          schedule_enabled: <%= ENV['TMPL_SCHEDULE_ENABLED'] %>
          schedule_freq_type: 4 <%= ENV['TMPL_SCHEDULE_FREQ_TYPE'] %>
          schedule_freq_interval: <%= ENV['TMPL_SCHEDULE_FREQ_INTERVAL'] %>
          schedule_freq_subday_type: <%= ENV['TMPL_SCHEDULE_FREQ_SUBDAY_TYPE']  %>
          schedule_freq_subday_interval: <%= ENV['TMPL_SCHEDULE_FREQ_SUBDAY_INTERVAL'] %>
          schedule_freq_relative_interval: <%= ENV['TMPL_SCHEDULE_FREQ_RELATIVE_INTERVAL'] %>
          schedule_freq_recurrence_factor: <%= ENV['TMPL_SCHEDULE_FREQ_RECURRENCE_FACTOR'] %>
          schedule_active_start_date: <%= ENV['TMPL_SCHEDULE_ACTIVE_START_DATE'] %>
          schedule_active_end_date: <%= ENV['TMPL_SCHEDULE_ACTIVE_END_DATE'] %>
          schedule_active_start_time: <%= ENV['TMPL_SCHEDULE_ACTIVE_START_TIME'] %>
          schedule_active_end_time: <%=  ENV['TMPL_SCHEDULE_ACTIVE_END_TIME'] %>
          job_steps:
            - id: 1
              name: Transform Step 1
              command: |
                EXEC sp_template;
                GO;
                SELECT GETDATE();
                GO;
            - id: 2
              name: Transform Step 2
              command: EXEC sp_template
      JOBTEMPLATE

      job_env_template = <<~ENVTEMPLATE
        TMPL_JOB_NAME=#{name}
        TMPL_ENABLED=true
        TMPL_NOTIFY_LEVEL_EMAIL=false
        TMPL_NOTIFY_LEVEL_NETSEND=false
        TMPL_NOTIFY_LEVEL_PAGE=false
        TMPL_DELETE_LEVEL=false
        TMPL_OWNER_LOGIN_NAME=SVC_DS_JOB
        TMPL_SCHEDULE_ENABLED=true
        TMPL_SCHEDULE_FREQ_TYPE=4
        TMPL_SCHEDULE_FREQ_INTERVAL=1
        TMPL_SCHEDULE_FREQ_SUBDAY_TYPE=8
        TMPL_SCHEDULE_FREQ_SUBDAY_INTERVAL=1
        TMPL_SCHEDULE_FREQ_RELATIVE_INTERVAL=0
        TMPL_SCHEDULE_FREQ_RECURRENCE_FACTOR=0
        TMPL_SCHEDULE_ACTIVE_START_DATE=20181010
        TMPL_SCHEDULE_ACTIVE_END_DATE=99991231
        TMPL_SCHEDULE_ACTIVE_START_TIME=000000
        TMPL_SCHEDULE_ACTIVE_END_TIME=235959
      ENVTEMPLATE

      # Re-define OS environment variable names with upper case, hyphen change to underscore. OS
      job_template.gsub!("TMPL_", "#{name.upcase.gsub('-','_')}_")
      job_env_template.gsub!("TMPL_", "#{name.upcase.gsub('-','_')}_")

      # Filename if contain underscore change to hyphen due to OCP meta config restriction
      job_file_name = "#{name.downcase.gsub('_','-')}.yaml"
      env_file_name = "#{name.downcase.gsub('_','-')}.env"

      FileUtils.mkdir_p(job_dir)
      FileUtils.mkdir_p(job_env_dir)

      job_file = File.join(job_dir, job_file_name)
      env_file = File.join(job_env_dir, env_file_name)

      File.open(job_file, 'w') do |file|
        file.write(job_template)
      end

      File.open(env_file, 'w') do |file|
        file.write(job_env_template)
      end

      puts "New job template is created: #{job_file}"
      puts "New environment template is created: #{env_file}"
    end


    def deploy

      job_db = db_connection


      # Begin transaction
      job_db.transaction do

        # Iterate over YAML files in job directory
        Dir.glob(File.join(job_dir, '*.yaml')) do |file|
          # Load configuration
          config = YAML.load(ERB.new(File.read(file)).result)

          puts "  >> Loading configuration from #{file}\n"

          #config_job_name = File.basename(file, ',*').chomp(File.extname(file))

          # Set variables
          category_name = config['category_name']
          owner_login_name = config['owner_login_name']
          database_name = ENV['DB_NAME']
          job_name = config['job_name']
          #schedule_uid = SecureRandom.uuid

          # Check if job exists
          if job_db.fetch("SELECT name FROM msdb.dbo.sysjobs WHERE name=?", job_name).count > 0

            # Delete job if exists
            job_db.call_mssql_sproc(:sp_delete_job, args:{
              'job_name' => job_name
            })
          end

          # Check if category exists
          if job_db.fetch("SELECT name FROM msdb.dbo.syscategories WHERE name=? AND category_class=1", category_name).count == 0

            job_db.call_mssql_sproc(:sp_add_category, args: {
              'class' => 'JOB',
              'type' => 'LOCAL',
              'name' => category_name
            })
          end

          # Creating job
          puts "  >> Creating job #{job_name}"
          job_id = job_db.call_mssql_sproc(:sp_add_job, args: {
            'job_name' => job_name,
            'enabled' => config['enabled'],
            'notify_level_eventlog' => 0,
            'notify_level_email' => config['notify_level_email'],
            'notify_level_netsend' => config['notify_level_netsend'],
            'notify_level_page' => config['notify_level_page'],
            'delete_level' => config['delete_level'],
            'description' => config['description'],
            'category_name' => category_name,
            'owner_login_name' => owner_login_name,
            'job_id' => [:output, 'uniqueidentifier', 'job_id']
            })[:job_id]

          # Iterate over job steps
          config['job_steps'].each_with_index do |step, index|
            # Merge step_general parameters with step parameters
            step = {
              'cmdexec_success_code' => 0,
              'on_success_action' => (index == config['job_steps'].length - 1) ? 1 : 3,
              'on_fail_action' => 2,
              'retry_attempts' => 0,
              'retry_interval' => 0,
              'os_run_priority' => 0,
              'subsystem' => 'TSQL',
              'database_name' => database_name
            }.merge(step)

            # Add job step
            puts "    >> Adding step #{step['name']}"
            job_db.call_mssql_sproc(:sp_add_jobstep, args: {
              'job_id' => job_id,
              'step_id' => step['id'],
              'step_name' => step['name'] || step['command'].split(' ')[1],
              'cmdexec_success_code' => step['cmdexec_success_code'],
              'on_success_action' => step['on_success_action'],
              'on_fail_action' => step['on_fail_action'],
              'retry_attempts' => step['retry_attempts'],
              'retry_interval' => step['retry_interval'],
              'os_run_priority' => step['os_run_priority'],
              'subsystem' => step['subsystem'],
              'command' => step['command'],
              'database_name' => step['database_name']
            })
          end

          # Update start step id of the job
          job_db.call_mssql_sproc(:sp_update_job, args: {
            'job_id' => job_id.to_s,
            'start_step_id' => 1
          })


          # Add schedule to the job
          puts "  >> Adding schedule to the job #{job_name}"
          job_db.call_mssql_sproc(:sp_add_jobschedule, args: {
            'job_id' => job_id,
            #':schedule_uid, type: :output},
            'name' => config['schedule_name'],
            'enabled' => config['schedule_enabled'],
            'freq_type' => config['schedule_freq_type'].to_i,
            'freq_interval' => config['schedule_freq_interval'].to_i,
            'freq_subday_type' => config['schedule_freq_subday_type'].to_i,
            'freq_subday_interval' => config['schedule_freq_subday_interval'].to_i,
            'freq_relative_interval' => config['schedule_freq_relative_interval'].to_i,
            'freq_recurrence_factor' => config['schedule_freq_recurrence_factor'].to_i,
            'active_start_date' => config['schedule_active_start_date'].to_i,
            'active_end_date' => config['schedule_active_end_date'].to_i,
            'active_start_time' => config['schedule_active_start_time'].to_i,
            'active_end_time' => config['schedule_active_end_time'].to_i
          })

          # Add server to the job
          puts "  >> Adding server to the job #{job_name}\n---------------------------------------------\n"
          job_db.call_mssql_sproc(:sp_add_jobserver, args: {
            'job_id' => job_id.to_s,
            'server_name' => '(local)'
          })

        end
      end

    end
  end
end