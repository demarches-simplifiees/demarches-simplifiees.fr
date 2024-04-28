# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: validate_procedure_liens'
  task validate_procedure_liens: :environment do
    puts "Running deploy task 'validate_procedure_liens'"

    procedures = Procedure.with_discarded.with_external_urls
    progress = ProgressReport.new(procedures.count)

    errors = []

    each_error = -> (procedure, &block) {
      procedure.errors.each do |error|
        case error.attribute
        when :lien_notice
          block.call :lien_notice, procedure.lien_notice
        when :lien_dpo
          block.call :lien_dpo, procedure.lien_dpo
        end
      end
    }

    procedures.find_each do |procedure|
      if !procedure.valid?
        each_error.(procedure) do |attribute, url|
          h = {}
          h[attribute] = url.strip.gsub(/[.;]$/, '').gsub(/^hhttps/, 'https').gsub(/^https\/\//, 'https://')
          procedure.assign_attributes(h)
        end

        if !procedure.save
          each_error.(procedure) do |attribute, url|
            if !url.match?(/@/) && !url.start_with?('http')
              h = {}
              h[attribute] = "https://#{url}"
              procedure.assign_attributes(h)
            end
          end

          if !procedure.save
            each_error.(procedure) do |attribute, url|
              h = {}
              h[attribute] = nil
              procedure.assign_attributes(h)
              errors << { attribute:, url: url.gsub('https://', '') }
            end
            procedure.save
          end
        end
      end
      progress.inc
    end

    progress.finish

    errors.each do |error|
      rake_puts "removed invalid #{error[:attribute]}: #{error[:url]}"
    end

    Procedure.with_external_urls.find_each { ::ProcedureExternalURLCheckJob.perform_later(_1) }

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
