# frozen_string_literal: true

class SelectProcedureDropDownListComponent < Dsfr::InputComponent
  def initialize(procedures:, action_path:, form_class: 'ml-auto')
    @procedures = procedures
    @action_path = action_path
    @form_class = form_class
  end

  def render?
    procedures_count > 3
  end

  def react_props
    {
      items:,
      placeholder: t('.placeholder'),
      name: "procedure_id",
      id: 'select-procedure-drop-down-list',
      'aria-describedby': 'select-procedure-drop-down-list-label',
      form: 'select-procedure-drop-down-list-component',
      data: {
        no_autosubmit: 'input blur',
        no_autosubmit_on_empty: 'true',
        autosubmit_target: 'input',
        action_path: @action_path,
      },
    }
  end

  def items
    @procedures.map { ["n°#{_1.id} - #{_1.libelle}", _1.id] }
  end

  private

  def procedures_count
    admin? ? @procedures.to_a.size : @procedures.count
  end

  def admin?
    @action_path.include?('admin')
  end
end
