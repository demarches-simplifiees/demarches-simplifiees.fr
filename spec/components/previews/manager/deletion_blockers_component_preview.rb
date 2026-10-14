# frozen_string_literal: true

class Manager::DeletionBlockersComponentPreview < ViewComponent::Preview
  # @param id number
  def default(id: nil)
    user = User.find_by(id:) || User.joins(:administrateur).first || User.first
    render(Manager::DeletionBlockersComponent.new(user:))
  end
end
