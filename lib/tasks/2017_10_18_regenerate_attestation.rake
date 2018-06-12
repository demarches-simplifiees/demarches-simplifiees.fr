require Rails.root.join("lib", "tasks", "task_helper")

namespace :'2017_10_18_regenerate_attestation' do
  task set: :environment do
    include ActiveSupport::Testing::TimeHelpers

    if ENV['ATTESTATION_ID'].present?
      regenerate_attestations(Attestation.find(ENV['ATTESTATION_ID']))
    else
      Attestation.all.each { |attestation| regenerate_attestations(attestation) }
    end
  end

  def regenerate_attestations(attestation)
    Procedure.unscoped do
      Dossier.unscoped do
        dossier = attestation.dossier
        procedure = dossier.procedure

        rake_puts "processing dossier #{dossier.id}"

        travel_to(dossier.processed_at) do
          new_attestation = procedure.attestation_template.attestation_for(dossier)
          attestation.delete
          dossier.attestation = new_attestation
          dossier.save
        end
      end
    end
  end
end
