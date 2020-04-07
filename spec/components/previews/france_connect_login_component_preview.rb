class FranceConnectLoginComponentPreview < ViewComponent::Preview
  layout :application_preview

  def default
    render FranceConnectLoginComponent.new(url: "/france-connect")
  end
end
