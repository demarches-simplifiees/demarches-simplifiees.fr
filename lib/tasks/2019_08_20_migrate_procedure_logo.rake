namespace :'2019_08_20_migrate_procedure_logo' do
  task run: :environment do
    procedures = Procedure.where
      .not(logo: nil)
      .left_joins(:logo_new_attachment)
      .where('active_storage_attachments.id IS NULL')
      .order(:created_at)

    limit = ENV['LIMIT']
    if limit
      procedures.limit!(limit.to_i)
    end

    progress = ProgressReport.new(procedures.count)
    procedures.find_each do |procedure|
      if procedure.logo.present?
        uri = URI.parse(URI.escape(procedure.logo_url))
        response = Typhoeus.get(uri)
        if response.success?
          filename = procedure.logo.filename || procedure.logo_identifier
          procedure.logo_new.attach(
            io: StringIO.new(response.body),
            filename: filename,
            content_type: procedure.logo.content_type,
            metadata: { virus_scan_result: ActiveStorage::VirusScanner::SAFE }
          )
        end
      end
      progress.inc
    end
    progress.finish
  end
end
