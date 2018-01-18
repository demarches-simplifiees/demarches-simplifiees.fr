module TagsSubstitutionConcern
  extend ActiveSupport::Concern

  include Rails.application.routes.url_helpers
  include ActionView::Helpers::UrlHelper

  def tags
    if procedure.for_individual?
      identity_tags = individual_tags
    else
      identity_tags = entreprise_tags + etablissement_tags
    end

    filter_tags(identity_tags + dossier_tags + procedure_type_de_champ_public_private_tags)
  end

  private

  def filter_tags(tags)
    # Implementation note: emails and attestation generations are generally
    # triggerred by changes to the dossier’s state. The email or attestation
    # is generated right after the dossier has reached its new state.
    #
    # DOSSIER_STATE should be equal to this new state.
    #
    # For instance, for an email that gets generated for the brouillon->en_construction
    # transition, DOSSIER_STATE should equal 'en_construction'.

    if !defined?(self.class::DOSSIER_STATE)
      raise NameError.new("The class #{self.class.name} includes TagsSubstitutionConcern, it should define the DOSSIER_STATE constant but it does not", :DOSSIER_STATE)
    end

    tags.select { |tag| (tag[:available_for_states] || Dossier::SOUMIS).include?(self.class::DOSSIER_STATE) }
  end

  def procedure_type_de_champ_public_private_tags
    (procedure.types_de_champ + procedure.types_de_champ_private)
      .map { |tdc| { libelle: tdc.libelle, description: tdc.description } }
  end

  def dossier_tags
    [
      {
        libelle: 'motivation',
        description: 'Motivation facultative associée à la décision finale d’acceptation, refus ou classement sans suite',
        target: :motivation,
        available_for_states: Dossier::TERMINE
      },
      {
        libelle: 'date de dépôt',
        description: 'Date du passage en construction du dossier par l’usager',
        lambda: -> (d) { format_date(d.en_construction_at) }
      },
      {
        libelle: 'date de passage en instruction',
        description: '',
        lambda: -> (d) { format_date(d.en_instruction_at) },
        available_for_states: Dossier::INSTRUCTION_COMMENCEE
      },
      {
        libelle: 'date de décision',
        description: 'Date de la décision d’acceptation, refus, ou classement sans suite',
        lambda: -> (d) { format_date(d.processed_at) },
        available_for_states: Dossier::TERMINE
      },
      { libelle: 'libellé procédure', description: '', lambda: -> (d) { d.procedure.libelle } },
      { libelle: 'numéro du dossier', description: '', target: :id }
    ]
  end

  def format_date(date)
    if date.present?
      date.localtime.strftime('%d/%m/%Y')
    else
      ''
    end
  end

  def dossier_tags_for_mail
    [{ libelle: 'lien dossier', description: '', lambda: -> (d) { users_dossier_recapitulatif_link(d) } }]
  end

  def users_dossier_recapitulatif_link(dossier)
    url = users_dossier_recapitulatif_url(dossier)
    link_to(url, url, target: '_blank')
  end

  def individual_tags
    [
      { libelle: 'civilité', description: 'M., Mme', target: :gender },
      { libelle: 'nom', description: "nom de l'usager", target: :nom },
      { libelle: 'prénom', description: "prénom de l'usager", target: :prenom }
    ]
  end

  def entreprise_tags
    [
      { libelle: 'SIREN', description: '', target: :siren },
      { libelle: 'numéro de TVA intracommunautaire', description: '', target: :numero_tva_intracommunautaire },
      { libelle: 'SIRET du siège social', description: '', target: :siret_siege_social },
      { libelle: 'raison sociale', description: '', target: :raison_sociale }
    ]
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
      [etablissement_tags, dossier.entreprise&.etablissement]
    ]

    tags_and_datas
      .map { |(tags, data)| [filter_tags(tags), data] }
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
