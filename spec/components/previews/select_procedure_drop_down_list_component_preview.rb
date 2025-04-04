# frozen_string_literal: true

class SelectProcedureDropDownListComponentPreview < ViewComponent::Preview
  def default
    @procedures = Procedure.limit(10)
    render(SelectProcedureDropDownListComponent.new(procedures: @procedures, action_path: '/test/path'))
  end
end
