class TypesDeChampEditor::ConditionsErrorsComponent < ApplicationComponent
  def initialize(conditions:, upper_tdcs:)
    @conditions, @upper_tdcs = conditions, upper_tdcs
  end

  private

  def errors
    @conditions
      .filter { |condition| condition.errors(@upper_tdcs.map(&:stable_id)).present? }
      .map { |condition| row_error(Logic.split_condition(condition)) }
      .uniq
      .map { |message| tag.li(message) }
      .then { |lis| tag.ul(lis.reduce(&:+)) }
  end

  def row_error((left, operator_name, right))
    targeted_champ = @upper_tdcs.find { |tdc| tdc.stable_id == left.stable_id }

    if targeted_champ.nil?
      t('not_available', scope: '.errors')
    elsif left.type == :unmanaged
      t('unmanaged', scope: '.errors',
        libelle: targeted_champ.libelle,
        type_champ: t(targeted_champ.type_champ, scope: '.type'))
    else
      t('incompatible', scope: '.errors',
        libelle: targeted_champ.libelle,
        type_champ: t(targeted_champ.type_champ, scope: '.type'),
        operator: t(operator_name, scope: 'logic.operators').downcase,
        right: right.to_s.downcase)
    end
  end

  def render?
    @conditions
      .filter { |condition| condition.errors(@upper_tdcs.map(&:stable_id)).present? }
      .present?
  end
end
