# frozen_string_literal: true

class Instructeurs::SelectProcedureDropDownListComponent < Dsfr::InputComponent
  def initialize(procedures:)
    @procedures = procedures
  end

  def react_props
    {
      items:,
      placeholder: t('.placeholder'),
      name: "procedure_id",
      id: 'select-procedure-drop-down-list',
      'aria-describedby': 'select-procedure-drop-down-list-label',
      form: 'select-procedure-drop-down-list-component',
      data: { no_autosubmit: 'input blur', no_autosubmit_on_empty: 'true', autosubmit_target: 'input' }
    }
  end

  def items
    @procedures.map { ["n°#{_1.id} - #{_1.libelle}", _1.id] }
  end
end
