# frozen_string_literal: true

class Champs::FormuleChamp < Champ
  before_save :compute_value

  validates :computed_value, presence: true, if: -> { type_de_champ.formule_expression.present? }

  def computed_value
    @computed_value
  end

  def computed_value=(val)
    @computed_value = val
  end

  def blank?
    value.blank?
  end

  def value
    @computed_value ||= compute_value_from_formula
  end

  def value=(val)
    # Formule fields are read-only, but we need this for form compatibility
    @computed_value = val
  end

  def for_export(path = :value)
    value
  end

  def for_api
    value
  end

  def for_api_v2
    value
  end

  def search_terms
    [value].compact
  end

  def to_s
    value.to_s
  end

  private

  def compute_value
    @computed_value = compute_value_from_formula
  end

  def compute_value_from_formula
    return '' if type_de_champ.formule_expression.blank?

    begin
      # TODO: Implement actual formula computation with Dentaku
      # For now, return a placeholder
      expression = type_de_champ.formule_expression
      
      # Simple placeholder - replace with actual Dentaku evaluation
      if expression.include?('{')
        # Extract field references for future dependency tracking
        field_references = expression.scan(/\{([^}]+)\}/)
        "Computed: #{field_references.length} field(s) referenced"
      else
        expression
      end
    rescue StandardError => e
      "Error: #{e.message}"
    end
  end
end