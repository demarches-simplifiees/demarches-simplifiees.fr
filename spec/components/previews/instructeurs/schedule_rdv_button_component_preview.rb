# frozen_string_literal: true

class Instructeurs::ScheduleRdvButtonComponentPreview < ViewComponent::Preview
  def default
    render(Instructeurs::ScheduleRdvButtonComponent.new(dossier: Dossier.new(id: 1, procedure: Procedure.new(id: 1))))
  end
end
