# frozen_string_literal: true

class Instructeurs::ProposeRdvButtonComponentPreview < ViewComponent::Preview
  def default
    render(Instructeurs::ProposeRdvButtonComponent.new(dossier: Dossier.new(id: 1, procedure: Procedure.new(id: 1))))
  end
end
