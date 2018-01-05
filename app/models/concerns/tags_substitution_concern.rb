module TagsSubstitutionConcern
  extend ActiveSupport::Concern

  def tags
    if procedure.for_individual?
      identity_tags = individual_tags
    else
      identity_tags = entreprise_tags + etablissement_tags
    end

    identity_tags + dossier_tags + procedure_type_de_champ_public_private_tags
  end

  private

  def procedure_type_de_champ_public_private_tags
    (procedure.types_de_champ + procedure.types_de_champ_private)
      .map { |tdc| { libelle: tdc.libelle, description: tdc.description } }
  end

  def dossier_tags
    [{ libelle: 'motivation', description: '', target: :motivation },
     { libelle: 'numéro du dossier', description: '', target: :id }]
  end

  def individual_tags
    [{ libelle: 'civilité', description: 'M., Mme', target: :gender },
     { libelle: 'nom', description: "nom de l'usager", target: :nom },
     { libelle: 'prénom', description: "prénom de l'usager", target: :prenom }]
  end

  def entreprise_tags
    [{ libelle: 'SIREN', description: '', target: :siren },
     { libelle: 'numéro de TVA intracommunautaire', description: '', target: :numero_tva_intracommunautaire },
     { libelle: 'SIRET du siège social', description: '', target: :siret_siege_social },
     { libelle: 'raison sociale', description: '', target: :raison_sociale }]
  end

  def etablissement_tags
    [{ libelle: 'adresse', description: '', target: :inline_adresse }]
  end

  def replace_tags(text, dossier)
    if text.nil?
      return ''
    end

    text = replace_type_de_champ_tags(text, procedure.types_de_champ, dossier.champs)
    text = replace_type_de_champ_tags(text, procedure.types_de_champ_private, dossier.champs_private)

    tags_and_datas = [
      [dossier_tags, dossier],
      [individual_tags, dossier.individual],
      [entreprise_tags, dossier.entreprise],
      [etablissement_tags, dossier.entreprise&.etablissement]]

    tags_and_datas.inject(text) { |acc, (tags, data)| replace_tags_with_values_from_data(acc, tags, data) }
  end

  def replace_type_de_champ_tags(text, types_de_champ, dossier_champs)
    types_de_champ.inject(text) do |acc, tag|
      champ = dossier_champs
        .select { |dossier_champ| dossier_champ.libelle == tag[:libelle] }
        .first

      replace_tag(acc, tag, champ)
    end
  end

  def replace_tags_with_values_from_data(text, tags, data)
    if data.present?
      tags.inject(text) do |acc, tag|
        replace_tag(acc, tag, data.send(tag[:target]))
      end
    else
      text
    end
  end

  def replace_tag(text, tag, value)
    libelle = Regexp.quote(tag[:libelle])

    # allow any kind of space (non-breaking or other) in the tag’s libellé to match any kind of space in the template
    # (the '\\ |' is there because plain ASCII spaces were escaped by preceding Regexp.quote)
    libelle.gsub!(/\\ |[[:blank:]]/, "[[:blank:]]")

    text.gsub(/--#{libelle}--/, value.to_s)
  end
end
