class AttestationTemplate < ApplicationRecord
  include ActionView::Helpers::NumberHelper

  belongs_to :procedure

  mount_uploader :logo, AttestationTemplateImageUploader
  mount_uploader :signature, AttestationTemplateImageUploader

  validate :logo_signature_file_size

  FILE_MAX_SIZE_IN_MB = 0.5

  def tags
    if procedure.for_individual?
      identity_tags = individual_tags
    else
      identity_tags = entreprise_tags + etablissement_tags
    end

    identity_tags + dossier_tags + procedure_type_de_champ_public_private_tags
  end

  def dup
    result = AttestationTemplate.new(title: title, body: body, footer: footer, activated: activated)

    if logo.present?
      CopyCarrierwaveFile::CopyFileService.new(self, result, :logo).set_file
    end

    if signature.present?
      CopyCarrierwaveFile::CopyFileService.new(self, result, :signature).set_file
    end

    result
  end

  private

  def logo_signature_file_size
    %i[logo signature]
      .select { |file_name| send(file_name).present? }
      .each { |file_name| file_size_check(file_name) }
  end

  def file_size_check(file_name)
    if send(file_name).file.size.to_f > FILE_MAX_SIZE_IN_MB.megabyte.to_f
      errors.add(file_name, " : vous ne pouvez pas charger une image de plus de #{number_with_delimiter(FILE_MAX_SIZE_IN_MB, locale: :fr)} Mo")
    end
  end

  def procedure_type_de_champ_public_private_tags
    (procedure.types_de_champ + procedure.types_de_champ_private)
      .map { |tdc| { libelle: tdc.libelle, description: tdc.description } }
  end

  def dossier_tags
    [{ libelle: 'motivation', description: '', target: 'motivation' }]
  end

  def individual_tags
    [{ libelle: 'civilité', description: 'M., Mme' },
     { libelle: 'nom', description: "nom de l'usager" },
     { libelle: 'prénom', description: "prénom de l'usager" }]
  end

  def entreprise_tags
    [{ libelle: 'SIREN', description: '' },
     { libelle: 'numéro de TVA intracommunautaire', description: '' },
     { libelle: 'SIRET du siège social', description: '' },
     { libelle: 'raison sociale', description: '' }]
  end

  def etablissement_tags
    [{ libelle: 'adresse', description: '' }]
  end
end
