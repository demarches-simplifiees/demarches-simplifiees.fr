module TagsSubstitutionConcern
  extend ActiveSupport::Concern

  include Rails.application.routes.url_helpers
  include ActionView::Helpers::UrlHelper

  DOSSIER_TAGS = [
    {
      libelle: 'motivation',
      description: 'Motivation facultative associée à la décision finale d’acceptation, refus ou classement sans suite',
      target: :motivation,
      available_for_states: Dossier::TERMINE
    },
    {
      libelle: 'date de dépôt',
      description: 'Date du passage en construction du dossier par l’usager',
      lambda: -> (d) { format_date(d.en_construction_at) },
      available_for_states: Dossier::SOUMIS
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
    {
      libelle: 'libellé démarche',
      description: '',
      lambda: -> (d) { d.procedure.libelle },
      available_for_states: Dossier::SOUMIS
    },
    {
      libelle: 'numéro du dossier',
      description: '',
      target: :id,
      available_for_states: Dossier::SOUMIS
    },
    {
      libelle: 'nom du service',
      description: 'Le nom du service instructeur qui traite le dossier',
      lambda: -> (d) { d.procedure.organisation_name || '' },
      available_for_states: Dossier::SOUMIS
    }
  ]

  DOSSIER_TAGS_FOR_MAIL = [
    {
      libelle: 'lien dossier',
      description: '',
      lambda: -> (d) { external_link(dossier_url(d)) },
      available_for_states: Dossier::SOUMIS
    },
    {
      libelle: 'lien attestation',
      description: '',
      lambda: -> (d) {
        links = [external_link(attestation_dossier_url(d))]
        if d.justificatif_motivation.attached?
          links.push external_link_with_body("Télécharger le justificatif", url_for_justificatif_motivation(d))
        end
        links.join "<br />\n"
      },
      available_for_states: [Dossier.states.fetch(:accepte)]
    }
  ]

  INDIVIDUAL_TAGS = [
    {
      libelle: 'civilité',
      description: 'M., Mme',
      target: :gender,
      available_for_states: Dossier::SOUMIS
    },
    {
      libelle: 'nom',
      description: "nom de l'usager",
      target: :nom,
      available_for_states: Dossier::SOUMIS
    },
    {
      libelle: 'prénom',
      description: "prénom de l'usager",
      target: :prenom,
      available_for_states: Dossier::SOUMIS
    }
  ]

  ENTREPRISE_TAGS = [
    {
      libelle: 'SIREN',
      description: '',
      target: :siren,
      available_for_states: Dossier::SOUMIS
    },
    {
      libelle: 'numéro de TVA intracommunautaire',
      description: '',
      target: :numero_tva_intracommunautaire,
      available_for_states: Dossier::SOUMIS
    },
    {
      libelle: 'SIRET du siège social',
      description: '',
      target: :siret_siege_social,
      available_for_states: Dossier::SOUMIS
    },
    {
      libelle: 'raison sociale',
      description: '',
      target: :raison_sociale,
      available_for_states: Dossier::SOUMIS
    },
    {
      libelle: 'adresse',
      description: '',
      target: :inline_adresse,
      available_for_states: Dossier::SOUMIS
    }
  ]

  def tags
    if procedure.for_individual?
      identity_tags = INDIVIDUAL_TAGS
    else
      identity_tags = ENTREPRISE_TAGS
    end

    filter_tags(identity_tags + dossier_tags + champ_public_tags + champ_private_tags)
  end

  private

  def format_date(date)
    if date.present?
      date.strftime('%d/%m/%Y')
    else
      ''
    end
  end

  def external_link(url)
    link_to(url, url, target: '_blank', rel: 'noopener')
  end

  def external_link_with_body(body, url)
    link_to(body, url, target: '_blank', rel: 'noopener')
  end

  def url_for_justificatif_motivation(dossier)
    if dossier.justificatif_motivation.attached?
      Rails.application.routes.url_helpers.url_for(dossier.justificatif_motivation)
    end
  end

  def dossier_tags
    # Overridden by MailTemplateConcern
    DOSSIER_TAGS
  end

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

    tags.select { |tag| tag[:available_for_states].include?(self.class::DOSSIER_STATE) }
  end

  def champ_public_tags
    types_de_champ_tags(procedure.types_de_champ, Dossier::SOUMIS)
  end

  def champ_private_tags
    types_de_champ_tags(procedure.types_de_champ_private, Dossier::INSTRUCTION_COMMENCEE)
  end

  def types_de_champ_tags(types_de_champ, available_for_states)
    tags = types_de_champ.flat_map(&:tags_for_template)
    tags.each do |tag|
      tag[:available_for_states] = available_for_states
    end
    tags
  end

  def replace_tags(text, dossier)
    if text.nil?
      return ''
    end

    tags_and_datas = [
      [champ_public_tags, dossier.champs],
      [champ_private_tags, dossier.champs_private],
      [dossier_tags, dossier],
      [INDIVIDUAL_TAGS, dossier.individual],
      [ENTREPRISE_TAGS, dossier.etablissement&.entreprise]
    ]

    tags_and_datas
      .map { |(tags, data)| [filter_tags(tags), data] }
      .inject(text) { |acc, (tags, data)| replace_tags_with_values_from_data(acc, tags, data) }
  end

  def replace_tags_with_values_from_data(text, tags, data)
    if data.present?
      tags.inject(text) do |acc, tag|
        replace_tag(acc, tag, data)
      end
    else
      text
    end
  end

  def replace_tag(text, tag, data)
    libelle = Regexp.quote(tag[:libelle])

    # allow any kind of space (non-breaking or other) in the tag’s libellé to match any kind of space in the template
    # (the '\\ |' is there because plain ASCII spaces were escaped by preceding Regexp.quote)
    libelle.gsub!(/\\ |[[:blank:]]/, "[[:blank:]]")

    if tag.key?(:target)
      value = data.send(tag[:target])
    else
      value = instance_exec(data, &tag[:lambda])
    end

    text.gsub(/--#{libelle}--/, value.to_s)
  end
end
