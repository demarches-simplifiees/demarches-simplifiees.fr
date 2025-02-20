# frozen_string_literal: true

class Procedure::Card::RdvComponentPreview < ViewComponent::Preview
  def default
    render(Procedure::Card::RdvComponent.new)
  end
end
