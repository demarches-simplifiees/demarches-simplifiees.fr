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
      description: 'Date de dépôt du dossier par l’usager',
      lambda: -> (d) { format_date(d.depose_at) },
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
      lambda: -> (d) { external_link(attestation_dossier_url(d)) },
      available_for_states: [Dossier.states.fetch(:accepte)]
    },
    {
      libelle: 'lien document justificatif',
      description: '',
      lambda: -> (d) {
        if d.justificatif_motivation.attached?
          external_link(url_for_justificatif_motivation(d), "Télécharger le document justificatif")
        else
          return "[l’instructeur n’a pas joint de document supplémentaire]"
        end
      },
      available_for_states: Dossier::TERMINE
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
      libelle: 'Numéro TAHITI du siège social',
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

  ROUTAGE_TAGS = [
    {
      libelle: 'groupe instructeur',
      description: 'Le groupe instructeur en charge du dossier',
      lambda: -> (d) { d.groupe_instructeur.label },
      available_for_states: Dossier::SOUMIS
    }
  ]

  SHARED_TAG_LIBELLES = (DOSSIER_TAGS + DOSSIER_TAGS_FOR_MAIL + INDIVIDUAL_TAGS + ENTREPRISE_TAGS + ROUTAGE_TAGS).map { |tag| tag[:libelle] }

  TAG_DELIMITERS_REGEX = /--(?<capture>((?!--).)*)--/

  def tags
    if procedure.for_individual?
      identity_tags = INDIVIDUAL_TAGS
    else
      identity_tags = ENTREPRISE_TAGS
    end

    routage_tags = []
    if procedure.routee?
      routage_tags = ROUTAGE_TAGS
    end

    filter_tags(identity_tags + dossier_tags + champ_public_tags + champ_private_tags + routage_tags)
  end

  def used_type_de_champ_tags(text)
    used_tags_for(text, with_libelle: true).filter_map do |(tag, libelle)|
      if !tag.in?(SHARED_TAG_LIBELLES)
        if tag.start_with?('tdc')
          [libelle, tag.gsub('tdc', '').to_i]
        else
          [tag]
        end
      end
    end
  end

  def used_tags_for(text, with_libelle: false)
    text, tags = normalize_tags(text)
    text
      .scan(TAG_DELIMITERS_REGEX)
      .flatten
      .map do |tag_str|
        if with_libelle
          tag = tags.find { |tag| tag[:id] == tag_str }
          [tag_str, tag ? tag[:libelle] : nil]
        else
          tag_str
        end
      end
  end

  private

  def format_date(date)
    if date.present?
      date.strftime('%d/%m/%Y')
    else
      ''
    end
  end

  def external_link(url, title = nil)
    link_to(title || url, url, target: '_blank', rel: 'noopener')
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

    tags.filter { |tag| tag[:available_for_states].include?(self.class::DOSSIER_STATE) }
  end

  def champ_public_tags(dossier: nil)
    types_de_champ = (dossier || procedure.active_revision).types_de_champ_public
    types_de_champ_tags(types_de_champ, Dossier::SOUMIS)
  end

  def champ_private_tags(dossier: nil)
    types_de_champ = (dossier || procedure.active_revision).types_de_champ_private
    types_de_champ_tags(types_de_champ, Dossier::INSTRUCTION_COMMENCEE)
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

    text, _ = normalize_tags(text)

    tags_and_datas = [
      [champ_public_tags(dossier: dossier), dossier.champs],
      [champ_private_tags(dossier: dossier), dossier.champs_private],
      [dossier_tags, dossier],
      [ROUTAGE_TAGS, dossier],
      [INDIVIDUAL_TAGS, dossier.individual],
      [ENTREPRISE_TAGS, dossier.etablissement&.entreprise]
    ]

    tags_and_datas
      .map { |(tags, data)| [filter_tags(tags), data] }
      .reduce(text) { |acc, (tags, data)| replace_tags_with_values_from_data(acc, tags, data) }
  end

  def replace_tags_with_values_from_data(text, tags, data)
    if data.present?
      tags.reduce(text) do |acc, tag|
        replace_tag(acc, tag, data)
      end
    else
      text
    end
  end

  def replace_tag(text, tag, data)
    libelle = Regexp.quote(tag[:id].presence || tag[:libelle])

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

  def used_tags
    delimiters_regex = /--(?<capture>((?!--).)*)--/

    # We can't use flat_map as scan will return 3 levels of array,
    # using flat_map would give us 2, whereas flatten will
    # give us 1, which is what we want
    [subject, body]
      .compact.map { |str| str.scan(delimiters_regex) }
      .flatten.to_set
  end

  def normalize_tags(text)
    tags = types_de_champ_tags(procedure.types_de_champ_public_for_tags, Dossier::SOUMIS) + types_de_champ_tags(procedure.types_de_champ_private_for_tags, Dossier::INSTRUCTION_COMMENCEE)
    [filter_tags(tags).reduce(text) { |text, tag| normalize_tag(text, tag) }, tags]
  end

  def normalize_tag(text, tag)
    libelle = Regexp.quote(tag[:libelle])

    # allow any kind of space (non-breaking or other) in the tag’s libellé to match any kind of space in the template
    # (the '\\ |' is there because plain ASCII spaces were escaped by preceding Regexp.quote)
    libelle.gsub!(/\\ |[[:blank:]]/, "[[:blank:]]")

    text.gsub(/--#{libelle}--/, "--#{tag[:id]}--")
  end
end
