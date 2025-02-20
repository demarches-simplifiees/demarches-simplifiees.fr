# frozen_string_literal: true

class Instructeurs::SelectProcedureDropDownListComponentPreview < ViewComponent::Preview
  def default
    @procedures = Procedure.limit(10)
    render(Instructeurs::SelectProcedureDropDownListComponent.new(procedures: @procedures))
  end
end
