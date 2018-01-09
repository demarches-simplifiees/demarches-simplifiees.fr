module TagsSubstitutionConcern
  extend ActiveSupport::Concern

  def tags(is_dossier_termine: true)
    if procedure.for_individual?
      identity_tags = individual_tags
    else
      identity_tags = entreprise_tags + etablissement_tags
    end

    tags = identity_tags + dossier_tags + procedure_type_de_champ_public_private_tags
    filter_tags(tags, is_dossier_termine)
  end

  private

  def filter_tags(tags, is_dossier_termine)
    if !is_dossier_termine
      tags.reject { |tag| tag[:dossier_termine_only] }
    else
      tags
    end
  end

  def procedure_type_de_champ_public_private_tags
    (procedure.types_de_champ + procedure.types_de_champ_private)
      .map { |tdc| { libelle: tdc.libelle, description: tdc.description } }
  end

  def dossier_tags
    [{ libelle: 'motivation',
       description: 'Motivation facultative associée à la décision finale d’acceptation, refus ou classement sans suite',
       target: :motivation,
       dossier_termine_only: true },
     { libelle: 'date de décision',
       description: 'Date de la décision d’acceptation, refus, ou classement sans suite',
       lambda: -> (d) { format_date(d.processed_at) },
       dossier_termine_only: true },
     { libelle: 'libellé procédure', description: '', lambda: -> (d) { d.procedure.libelle } },
     { libelle: 'numéro du dossier', description: '', target: :id }]
  end

  def format_date(date)
    if date.present?
      date.localtime.strftime('%d/%m/%Y')
    else
      ''
    end
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

    tags_and_datas
      .map { |(tags, data)| [filter_tags(tags, dossier.termine?), data] }
      .inject(text) { |acc, (tags, data)| replace_tags_with_values_from_data(acc, tags, data) }
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
        if tag.key?(:target)
          value = data.send(tag[:target])
        else
          value = tag[:lambda].(data)
        end
        replace_tag(acc, tag, value)
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
