# frozen_string_literal: true

class Administrateurs::SelectProcedureDropDownListComponentPreview < ViewComponent::Preview
  def default
    @procedures = Procedure.limit(10)
    render(Administrateurs::SelectProcedureDropDownListComponent.new(procedures: @procedures))
  end
end
