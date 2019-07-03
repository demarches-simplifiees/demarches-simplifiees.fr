namespace :after_party do
  desc 'Deployment task: set_declarative_procedures'
  task set_declarative_procedures: :environment do
    puts "Running deploy task 'set_declarative_procedures'"

    Delayed::Job.where.not(cron: nil).find_each do |job|
      job_data = YAML.load_dj(job.handler).job_data

      if job_data['job_class'] == 'AutoReceiveDossiersForProcedureJob'
        procedure_id, state = job_data['arguments']
        procedure = Procedure.find(procedure_id)
        procedure.declarative_with_state = state
        procedure.save!
        job.delete
      end
    end

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord.create version: '20190523122639'
  end
end
