class TypesDeChamp::ConditionsComponent < ApplicationComponent
  include Logic

  def initialize(tdc:, upper_tdcs:, procedure_id:)
    @tdc, @condition, @upper_tdcs = tdc, tdc.condition, upper_tdcs
    @procedure_id = procedure_id
  end

  private

  def rows
    condition_per_row.map { |c| Logic.split_condition(c) }
  end

  def condition_per_row
    if [And, Or].include?(@condition.class)
      @condition.operands
    else
      [@condition].compact
    end
  end

  def logic_conditionnel_button
    if @condition.nil?
      submit_tag('cliquer pour activer', formaction: add_row_admin_procedure_condition_path(@procedure_id, @tdc.id))
    else
      submit_tag(
        'cliquer pour désactiver',
        formmethod: 'delete',
        formnovalidate: true,
        data: { confirm: "La logique conditionnelle appliquée à ce champ sera désactivé.\nVoulez-vous continuer ?" }
      )
    end
  end

  def far_left_tag(row_number)
    if row_number == 0
      'Afficher si'
    elsif row_number == 1
      select_tag(
        "#{input_prefix}[top_operator_name]",
        options_for_select([['Et', And.name], ['Ou', Or.name]], @condition.class.name)
      )
    end
  end

  def left_operand_tag(targeted_champ, row_index)
    current_target_valid = targets.map(&:second).include?(targeted_champ.to_json)

    selected_target = current_target_valid ? targeted_champ.to_json : empty.to_json

    select_tag(
      input_name_for('targeted_champ'),
      options_for_select(targets, selected_target),
      onchange: "this.form.action = this.form.action + '/change_targeted_champ?row_index=#{row_index}'",
      id: input_id_for('targeted_champ', row_index),
      class: { alert: !current_target_valid }
    )
  end

  def targets
    available_targets
      .then { |targets| targets.unshift(['Sélectionner', empty.to_json]) }
  end

  def available_targets
    @upper_tdcs
      .filter { |tdc| ChampValue::MANAGED_TYPE_DE_CHAMP.values.include?(tdc.type_champ) }
      .map { |tdc| [tdc.libelle, champ_value(tdc.stable_id).to_json] }
  end

  def operator_tag(operator_name, targeted_champ, row_index)
    ops = compatibles_operators(targeted_champ)

    current_operator_valid = ops.map(&:second).include?(operator_name)

    if !current_operator_valid
      ops.unshift(['Sélectionner', EmptyOperator.name])
    end

    select_tag(
      input_name_for('operator_name'),
      options_for_select(ops, selected: operator_name),
      id: input_id_for('operator_name', row_index),
      class: { alert: !current_operator_valid }
    )
  end

  def compatibles_operators(left)
    case left.type
    when ChampValue::CHAMP_VALUE_TYPE.fetch(:boolean)
      [
        ['Est', Eq.name]
      ]
    when ChampValue::CHAMP_VALUE_TYPE.fetch(:empty)
      [
        ['Est', EmptyOperator.name]
      ]
    when ChampValue::CHAMP_VALUE_TYPE.fetch(:enum)
      [
        ['Est', Eq.name]
      ]
    when ChampValue::CHAMP_VALUE_TYPE.fetch(:number)
      [Eq, LessThan, GreaterThan, LessThanEq, GreaterThanEq]
        .map(&:name)
        .map { |name| [t(name, scope: 'logic.operators'), name] }
    else
      []
    end
  end

  def right_operand_tag(left, right, row_index)
    right_valid = current_right_valid?(left, right)

    case left.type
    when :boolean
      options = [['Oui', constant(true).to_json], ['Non', constant(false).to_json]]

      if !right_valid
        options.unshift(['Sélectionner', empty])
      end

      select_tag(
        input_name_for('value'),
        options_for_select(options, right.to_json),
        id: input_id_for('value', row_index),
        class: right_valid ? nil : 'alert'
      )
    when :empty
      select_tag(
        input_name_for('value'),
        options_for_select([['Sélectionner', empty.to_json]]),
        id: input_id_for('value', row_index)
      )
    when :enum
      options = left.options

      if !right_valid
        options.unshift(['Sélectionner', empty])
      end

      select_tag(
        input_name_for('value'),
        options_for_select(options, right.value),
        id: input_id_for('value', row_index),
        class: right_valid ? nil : 'alert'
      )
    when :number
      number_field_tag(
        input_name_for('value'),
        right.value,
        required: true,
        id: input_id_for('value', row_index),
        class: right_valid ? nil : 'alert'
      )
    else
      number_field_tag(input_name_for('value'), '', id: input_id_for('value', row_index))
    end
  end

  def current_right_valid?(left, right)
    case [left.type, right.type]
    in [:boolean, :boolean] | [:number, :number] | [:empty, :empty]
      true
    in [:enum, :string]
      left.options.include?(right.value)
    else
      false
    end
  end

  def add_condition_tag
    tag.button(
      tag.span('', class: 'icon add') + tag.span("Ajouter une condition"),
      formaction: add_row_admin_procedure_condition_path(@procedure_id, @tdc.id),
      formnovalidate: true,
      class: 'add-row'
    )
  end

  def delete_condition_tag(row_index)
    tag.button(
      tag.span('', class: 'icon delete') + tag.span('Supprimer la ligne', class: 'sr-only'),
      formaction: delete_row_admin_procedure_condition_path(@procedure_id, @tdc.id, row_index: row_index),
      formmethod: 'delete',
      formnovalidate: true
    )
  end

  def render?
    @condition.present? || available_targets.any?
  end

  def input_name_for(name)
    "#{input_prefix}[rows][][#{name}]"
  end

  def input_id_for(name, row_index)
    "#{@tdc.id}-#{name}-#{row_index}"
  end

  def input_prefix
    'type_de_champ[condition_form]'
  end
end
