module DocumentTemplateConcern
  extend ActiveSupport::Concern

  include Rails.application.routes.url_helpers
  include ActionView::Helpers::UrlHelper

  def tags(for_closed_dossier: true, reject_legacy: true)
    if procedure.for_individual?
      identity_tags = individual_tags
    else
      identity_tags = entreprise_tags + etablissement_tags
    end

    tags = identity_tags + dossier_tags + lambda_tags + procedure_type_de_champ_public_private_tags
    filter_tags(tags, for_closed_dossier)
      .reject { |tag| reject_legacy and tag[:is_legacy] }
  end

  private

  def filter_tags(tags, for_closed_dossier)
    tags.select { |tag| for_closed_dossier or not tag[:only_closed_dossier] }
  end

  def dossier_tags
    [{ libelle: 'numéro du dossier', description: '', target: :id },
     # TODO remove legacy tag after data migration
     { libelle: 'numero_dossier', description: '', target: :id, is_legacy: true },
     { libelle: 'motivation',
       description: 'Motivation facultative associée à la décision finale d’acceptation, refus ou classement sans suite',
       target: :motivation,
       only_closed_dossier: true }]
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

  def lambda_tags
    [{ libelle: 'date de décision',
       description: 'Date de la décision d’acceptation, refus, ou classement sans suite',
       lambda: -> (d) { d.processed_at.present? ? d.processed_at.localtime.strftime('%d/%m/%Y') : '' },
       only_closed_dossier: true },
     { libelle: 'libellé procédure', description: '', lambda: -> (d) { d.procedure.libelle } },
     { libelle: 'lien dossier', description: '', lambda: -> (d) { format_link(users_dossier_recapitulatif_url(d)) } },
     # TODO remove legacy tag after data migration
     { libelle: 'date_de_decision', description: '', is_legacy: true , only_closed_dossier: true,
       lambda: -> (d) { d.processed_at.present? ? d.processed_at.localtime.strftime('%d/%m/%Y') : '' } },
     { libelle: 'libelle_procedure', description: '', lambda: -> (d) { d.procedure.libelle }, is_legacy: true },
     { libelle: 'lien_dossier', description: '', lambda: -> (d) { format_link(users_dossier_recapitulatif_url(d)) }, is_legacy: true }]
  end

  def format_link(url)
    link_to url, url, target: '_blank'
  end

  def procedure_type_de_champ_public_private_tags
    (procedure.types_de_champ + procedure.types_de_champ_private)
      .map { |tdc| { libelle: tdc.libelle, description: tdc.description } }
  end

  def replace_tags(text, dossier, for_closed_dossier: true)
    if text.nil?
      return ''
    end

    text = replace_type_de_champ_tags(text, procedure.types_de_champ, dossier.champs)
    text = replace_type_de_champ_tags(text, procedure.types_de_champ_private, dossier.champs_private)

    text = filter_tags(lambda_tags, for_closed_dossier)
      .inject(text) { |acc, tag | replace_tag(acc, tag, tag[:lambda].(dossier)) }

    tags_and_datas = [
      [dossier_tags, dossier],
      [individual_tags, dossier.individual],
      [entreprise_tags, dossier.entreprise],
      [etablissement_tags, dossier.entreprise&.etablissement]]

    tags_and_datas
      .map { |(tags, data)| [filter_tags(tags, for_closed_dossier), data]}
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
