# frozen_string_literal: true

class Instructeurs::CustomizeFiltersComponentPreview < ViewComponent::Preview
  def default
    render(Instructeurs::CustomizeFiltersComponent.new)
  end
end
