# frozen_string_literal: true

class Instructeurs::ProposeRdvMenuContentComponentPreview < ViewComponent::Preview
  def default
    render(Instructeurs::ProposeRdvMenuContentComponent.new(dossier: "dossier"))
  end
end
