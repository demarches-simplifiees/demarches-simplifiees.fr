namespace :'2019_08_22_migrate_attestation_files' do
  task migrate_attestation_pdf: :environment do
    attestations = Attestation.where
      .not(pdf: nil)
      .left_joins(:pdf_active_storage_attachment)
      .where('active_storage_attachments.id IS NULL')
      .order(:created_at)

    limit = ENV['LIMIT']
    if limit
      attestations.limit!(limit.to_i)
    end

    progress = ProgressReport.new(attestations.count)
    attestations.find_each do |attestation|
      if attestation.pdf.present?
        uri = URI.parse(URI.escape(attestation.pdf_url))
        response = Typhoeus.get(uri)
        if response.success?
          filename = attestation.pdf.filename || attestation.pdf_identifier
          attestation.pdf_active_storage.attach(
            io: StringIO.new(response.body),
            filename: filename,
            content_type: attestation.pdf.content_type,
            metadata: { virus_scan_result: ActiveStorage::VirusScanner::SAFE }
          )
        end
      end
      progress.inc
    end
    progress.finish
  end

  task migrate_attestation_template_logo: :environment do
    attestation_templates = AttestationTemplate.where
      .not(logo: nil)
      .left_joins(:logo_active_storage_attachment)
      .where('active_storage_attachments.id IS NULL')
      .order(:created_at)

    limit = ENV['LIMIT']
    if limit
      attestation_templates.limit!(limit.to_i)
    end

    progress = ProgressReport.new(attestation_templates.count)
    attestation_templates.find_each do |attestation_template|
      if attestation_template.logo.present?
        uri = URI.parse(URI.escape(attestation_template.logo_url))
        response = Typhoeus.get(uri)
        if response.success?
          filename = attestation_template.logo.filename || attestation_template.logo_identifier
          attestation_template.logo_active_storage.attach(
            io: StringIO.new(response.body),
            filename: filename,
            content_type: attestation_template.logo.content_type,
            metadata: { virus_scan_result: ActiveStorage::VirusScanner::SAFE }
          )
        end
      end
      progress.inc
    end
    progress.finish
  end

  task migrate_attestation_template_signature: :environment do
    attestation_templates = AttestationTemplate.where
      .not(signature: nil)
      .left_joins(:signature_active_storage_attachment)
      .where('active_storage_attachments.id IS NULL')
      .order(:created_at)

    limit = ENV['LIMIT']
    if limit
      attestation_templates.limit!(limit.to_i)
    end

    progress = ProgressReport.new(attestation_templates.count)
    attestation_templates.find_each do |attestation_template|
      if attestation_template.signature.present?
        uri = URI.parse(URI.escape(attestation_template.signature_url))
        response = Typhoeus.get(uri)
        if response.success?
          filename = attestation_template.signature.filename || attestation_template.signature_identifier
          attestation_template.signature_active_storage.attach(
            io: StringIO.new(response.body),
            filename: filename,
            content_type: attestation_template.signature.content_type,
            metadata: { virus_scan_result: ActiveStorage::VirusScanner::SAFE }
          )
        end
      end
      progress.inc
    end
    progress.finish
  end
end
