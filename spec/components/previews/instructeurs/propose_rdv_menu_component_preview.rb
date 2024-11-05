# frozen_string_literal: true

class Instructeurs::ProposeRdvMenuComponentPreview < ViewComponent::Preview
  def default
    render(Instructeurs::ProposeRdvMenuComponent.new(dossier: "dossier"))
  end
end
