class TypesDeChampEditor::ConditionsErrorsComponent < ApplicationComponent
  def initialize(conditions:, upper_tdcs:)
    @conditions, @upper_tdcs = conditions, upper_tdcs
  end

  private

  def errors
    @conditions
      .flat_map { |condition| condition.errors(@upper_tdcs.map(&:stable_id)) }
      .map { |error| humanize(error) }
      .uniq
      .map { |message| tag.li(message) }
      .then { |lis| tag.ul(lis.reduce(&:+)) }
  end

  def humanize(error)
    case error
    in { type: :not_available }
      t('not_available', scope: '.errors')
    in { type: :unmanaged, stable_id: stable_id }
      targeted_champ = @upper_tdcs.find { |tdc| tdc.stable_id == stable_id }
      t('unmanaged',
        scope: '.errors',
        libelle: targeted_champ.libelle,
        type_champ: t(targeted_champ.type_champ, scope: 'activerecord.attributes.type_de_champ.type_champs')&.downcase)
    in { type: :incompatible, stable_id: stable_id, right: right, operator_name: operator_name }
      targeted_champ = @upper_tdcs.find { |tdc| tdc.stable_id == stable_id }
      t('incompatible', scope: '.errors',
        libelle: targeted_champ.libelle,
        type_champ: t(targeted_champ.type_champ, scope: 'activerecord.attributes.type_de_champ.type_champs')&.downcase,
        operator: t(operator_name, scope: 'logic.operators').downcase,
        right: right.to_s.downcase)
    in { type: :required_number, operator_name: operator_name }
      t('required_number', scope: '.errors',
        operator: t(operator_name, scope: 'logic.operators'))
    in { type: :not_included, stable_id: stable_id, right: right }
      targeted_champ = @upper_tdcs.find { |tdc| tdc.stable_id == stable_id }
      t('not_included', scope: '.errors',
        libelle: targeted_champ.libelle,
        right: right.to_s.downcase)
    in { type: :required_list }
      t('required_list', scope: '.errors')
    else
      nil
    end
  end

  def render?
    @conditions
      .filter { |condition| condition.errors(@upper_tdcs.map(&:stable_id)).present? }
      .present?
  end
end
