class ProcedureLinter
  attr_reader :procedure, :tdcs, :rules

  RULES = [
    :uppercase_in_libelles?,
    :too_long_libelle?,
    :optional_and_no_condition?,
    :missnamed_libelle?,
    :no_header_section?,
    :nom_prenom_for_individual?,
    :first_champ_is_siret_for_moral_procedure?,
    :notice_missing?,
    :extra_address_champs?,
    :entreprise_champ_after_siret?
  ]

  ComputedRule = Data.define(:pass, :details) do
    def score
      details.size
    end
  end

  Rule = Data.define(:pass, :details) do
    def score
      1
    end
  end

  def initialize(procedure, revision)
    @procedure = procedure
    @tdcs = revision.types_de_champ_public
  end

  def quali_score
    "#{details.values.count(&:pass)}/#{details.values.size}"
  end

  def perfect_rate?
    details.values.count(&:pass) == details.values.size
  end

  def top_rate
    details.values.size
  end

  def rate
    details.values.count(&:pass)
  end

  def score
    details.values.sum(&:score)
  end

  def details
    @computed ||= RULES.index_with { |method_name| send(method_name) }
  end

  def too_long_libelle?
    errored = tdcs.filter { _1.libelle.size > 80 }

    ComputedRule.new(errored.empty?, errored.map { [_1.stable_id, _1.libelle] })
  end

  def uppercase_in_libelles?
    errored = tdcs.filter { mostly_uppercase?(_1.libelle) }

    ComputedRule.new(errored.empty?, errored.map { [_1.stable_id, _1.libelle] })
  end

  def optional_and_no_condition?
    return Rule.new(true, {}) if tdcs.size < 100 || tdcs.any?(&:condition)
    mandatory = tdcs.count(&:mandatory?).to_f
    Rule.new((mandatory / tdcs.size.to_f) > 0.3, { total: tdcs.size, mandatory: mandatory })
  end

  def missnamed_libelle?
    forbidden_words_by_ditp = [
      'Dans le cadre de', 'Dans le but de', 'En ce qui concerne', 'Par conséquent', "L’administration ", "Le service", "l’agent", "usager", "
bénéficiaire", "demandeur", "Souscrire une demande", "Proroger", "Stipuler", "Au titre de l’article ", "Se référer au service", "Récépissé", "Faire parvenir", "Recouvrer
", "Tacite", "Il vous revient de", "Aux fins de"
    ]
    errored = tdcs.filter { |tdc| forbidden_words_by_ditp.any? { _1.downcase.in?(tdc.libelle.downcase) } }

    ComputedRule.new(errored.empty?, errored.map { [_1.stable_id, _1.libelle] })
  end

  def no_header_section?
    return Rule.new(true, "") if tdcs.size < 20

    Rule.new(tdcs.any?(&:header_section?), "")
  end

  def nom_prenom_for_individual?
    errored = tdcs.filter { |tdc| tdc.libelle.match?(/^(pr*)?nom$/i) }
    ComputedRule.new(errored.empty?, errored.map { [_1.stable_id, _1.libelle] })
  end

  def first_champ_is_siret_for_moral_procedure?
    return Rule.new(true, {}) if procedure.for_individual?

    first_tdc_is_siret = tdcs.first.siret?
    Rule.new(first_tdc_is_siret, [[tdcs.first.stable_id, tdcs.first.libelle]])
  end

  def notice_missing?
    Rule.new(procedure.notice.present?, "")
  end

  def extra_address_champs?
    errored = tdcs.filter.with_index { |tdc, i| i < tdcs.size - 1 && tdc.address? && tdcs[i + 1].communes? }

    ComputedRule.new(errored.empty?, errored.map { [_1.stable_id, _1.libelle] })
  end

  def entreprise_champ_after_siret?
    matchers = %w[adresse entreprise]
    errored = tdcs.filter.with_index { |tdc, i| i < tdcs.size - 1 && tdc.siret? && matchers.all? { |comp| /#{comp}/i.match?(tdcs[i + 1].libelle) } }

    ComputedRule.new(errored.empty?, errored.map { [_1.stable_id, _1.libelle] })
  end

  def mostly_uppercase?(sentence)
    words = sentence.scan(/[A-Za-z]+/) # Extract words, ignoring numbers and symbols
    return false if words.empty? # Return false if no words found

    uppercase_count = words.count { |word| word == word.upcase }

    (uppercase_count.to_f / words.size) > 0.8
  end
end
