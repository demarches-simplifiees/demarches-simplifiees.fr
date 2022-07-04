class TypesDeChamp::ConditionsErrorsComponent < ApplicationComponent
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
      "Un champ cible n'est plus disponible. Il est soit supprimé, soit déplacé en dessous de ce champ."
    elsif left.type == :unmanaged
      "Le champ « #{targeted_champ.libelle} » de type #{targeted_champ.type_champ} ne peut pas être utilisé comme champ cible."
    else
      "Le champ « #{targeted_champ.libelle} » est #{t(left.type, scope: '.type')}. Il ne peut pas être #{t(operator_name, scope: 'logic.operators').downcase} #{right.to_s.downcase}."
    end
  end

  def render?
    @conditions
      .filter { |condition| condition.errors(@upper_tdcs.map(&:stable_id)).present? }
      .present?
  end
end
