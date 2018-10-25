namespace :'2018_09_12_fix_templates' do
  task run: :environment do
    dossiers_with_invalid_attestations = find_dossiers_with_sent_and_invalid_attestations
    fix_templates
    fixed_attestations = delete_then_regenerate_attestations(dossiers_with_invalid_attestations)
    send_regenerated_attestations(dossiers_with_invalid_attestations)
  end

  # 16:15 in Paris -> 14:15 UTC
  DEPLOY_DATETIME = DateTime.new(2018, 9, 5, 14, 15, 0)

  def find_dossiers_with_sent_and_invalid_attestations
    invalid_procedures_ids = AttestationTemplate
      .where("body LIKE '%--libellé procédure--%'")
      .pluck(:procedure_id)

    dossiers_with_invalid_template_ids = Dossier
      .where(procedure_id: invalid_procedures_ids)
      .where(processed_at: DEPLOY_DATETIME..Time.zone.now)
      .pluck(:id)

    Attestation
      .includes(:dossier)
      .where(created_at: DEPLOY_DATETIME..Time.zone.now)
      .where(dossier_id: dossiers_with_invalid_template_ids)
      .map(&:dossier)
  end

  def fix_templates
    klasses = [
      Mails::ClosedMail,
      Mails::InitiatedMail,
      Mails::ReceivedMail,
      Mails::RefusedMail,
      Mails::WithoutContinuationMail,
      AttestationTemplate
    ]

    klasses.each do |klass|
      klass
        .where("body LIKE '%--libellé procédure--%'")
        .each do |instance|

        instance.update(body: instance.body.gsub("--libellé procédure--", "--libellé démarche--"))
        rake_puts "Body mis-à-jour pour #{klass.to_s}##{instance.id}"
      end
    end
  end

  def delete_then_regenerate_attestations(dossiers_with_invalid_attestations)
    dossiers_with_invalid_attestations.each do |dossier|
      begin
        dossier.attestation.destroy

        dossier.attestation = dossier.build_attestation
        dossier.save

        rake_puts "Attestation regénérée pour le dossier #{dossier.id}"
      rescue
        rake_puts "Erreur lors de la régénération de l'attestation pour le dossier #{dossier.id}"
      end
    end
  end

  def send_regenerated_attestations(dossiers_with_invalid_attestations)
    dossiers_with_invalid_attestations.each do |dossier|
      begin
        ResendAttestationMailer.resend_attestation(dossier).deliver_later
        rake_puts "Email envoyé à #{dossier.user.email} pour le dossier #{dossier.id}"
      rescue
        rake_puts "Erreur lors de l'envoi de l'email à #{dossier.user.email} pour le dossier #{dossier.id}"
      end
    end
  end
end
