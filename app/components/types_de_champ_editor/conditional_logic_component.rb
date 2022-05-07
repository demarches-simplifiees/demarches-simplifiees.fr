class TypesDeChampEditor::ConditionalLogicComponent < ApplicationComponent
  def initialize(type_de_champ:)
    @type_de_champ = type_de_champ
  end

  attr_reader :type_de_champ

  def render?
    @type_de_champ.conditional_logic_enabled? && @type_de_champ.siblings_that_can_have_conditional_logic.present?
  end

  def types_de_champ_before
    types_de_champ = @type_de_champ
      .siblings_that_can_have_conditional_logic
      .map do |type_de_champ|
        [type_de_champ.libelle, type_de_champ.stable_id]
      end

    if @type_de_champ.condition_source_valid?
      types_de_champ
    else
      [['Invalide', @type_de_champ.condition_source]] + types_de_champ
    end
  end

  def operators
    @type_de_champ.condition_source_type_de_champ&.condition_operators || []
  end

  def values
    values = @type_de_champ.condition_source_type_de_champ&.condition_values || []
    if values.in?([:text, :number])
      values
    elsif @type_de_champ.condition_value_valid?
      values
    else
      [['Invalide', @type_de_champ.condition_value]] + values
    end
  end

  def condition_needs_value?
    !@type_de_champ.condition_operator.in?(['is_blank', 'is_not_blank'])
  end

  def type_de_champ_path
    admin_procedure_type_de_champ_path(type_de_champ.procedure, type_de_champ.stable_id)
  end

  def form_options(class_name: '')
    {
      url: type_de_champ_path,
      multipart: true,
      html: { class: "form #{class_name}", data: { controller: 'submit' } }
    }
  end

  def invalid_source_class
    type_de_champ.condition_source_valid? ? '' : 'invalid'
  end

  def invalid_value_class
    type_de_champ.condition_value_valid? ? '' : 'invalid'
  end
end
