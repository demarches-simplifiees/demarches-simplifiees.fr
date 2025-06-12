# frozen_string_literal: true

class TypesDeChamp::FormuleTypeDeChamp < TypesDeChamp::TypeDeChampBase
  def initialize(type_de_champ)
    super
    validate_expression
  end

  def estimated_fill_duration(revision)
    0.seconds
  end

  private

  def validate_expression
    return if @type_de_champ.formule_expression.blank?

    # TODO: Add Dentaku validation here when gem is added
    # For now, basic syntax validation
    expression = @type_de_champ.formule_expression.strip

    if expression.length > 1000
      @type_de_champ.errors.add(:formule_expression, :too_long, count: 1000)
    end

    # Basic check for mustache syntax references
    if expression.scan(/\{[^}]*\}/).any? { |ref| ref.length < 3 }
      @type_de_champ.errors.add(:formule_expression, :invalid_field_reference)
    end
  rescue StandardError => e
    @type_de_champ.errors.add(:formule_expression, :invalid_syntax, message: e.message)
  end
end