class ClonePiecesJustificativesService
  def self.clone_attachments(original, kopy)
    case original
    when Champs::PieceJustificativeChamp, Champs::TitreIdentiteChamp
      original.piece_justificative_file.attachments.each do |attachment|
        kopy.piece_justificative_file.attach(attachment.blob)
      end
    when TypeDeChamp
      clone_attachment(original, kopy, :piece_justificative_template)
    when Procedure
      clone_attachment(original, kopy, :logo)
      clone_attachment(original, kopy, :notice)
      clone_attachment(original, kopy, :deliberation)
    when AttestationTemplate
      clone_attachment(original, kopy, :logo)
      clone_attachment(original, kopy, :signature)
    when Etablissement
      clone_attachment(original, kopy, :entreprise_attestation_sociale)
      clone_attachment(original, kopy, :entreprise_attestation_fiscale)
    end
  end

  def self.clone_attachment(original, kopy, attachment_name)
    attachment = original.public_send(attachment_name)
    if attachment.attached?
      kopy.public_send(attachment_name).attach(attachment.blob)
    end
  end
end
