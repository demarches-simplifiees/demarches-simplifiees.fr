namespace :'2018_06_05_resend_attestations' do
  task set: :environment do
    procedure = Procedure.find(4247)
    dossiers = procedure.dossiers.includes(:attestation).where(state: 'accepte').select do |d|
      d.processed_at < procedure.attestation_template.updated_at
    end

    dossiers.each do |dossier|
      attestation = dossier.attestation
      attestation.destroy

      dossier.attestation = dossier.build_attestation

      ResendAttestationMailer.resend_attestation(dossier).deliver_later
      puts "Email envoyé à #{dossier.user.email} pour le dossier #{dossier.id}"
    end
  end
end
