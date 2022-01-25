namespace :hotfix do
  desc 'Fix attestation templates'
  task attestation_templates: :environment do
    attestation_templates = Rails.root.join('lib', 'tasks', 'attestation_templates.json')
    file = File.read attestation_templates
    json = JSON.parse file
    progress = ProgressReport.new(json.size)

    json.each do |row|
      attestation_template = AttestationTemplate.find_by(id: row['id'])
      procedure = Procedure.find_by(id: row['procedure_id'])
      if attestation_template.present? && procedure.present?
        attestation_template.update_column(:procedure_id, procedure.id)
      end
      progress.inc
    end
    progress.finish
  end
end
