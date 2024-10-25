# frozen_string_literal: true

class Instructeurs::RdvCardComponentPreview < ViewComponent::Preview
  def default
    render(Instructeurs::RdvCardComponent.new(rdv: Rdv.new(starts_at: Time.zone.now)))
  end
end
