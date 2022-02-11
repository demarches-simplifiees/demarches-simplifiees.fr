module FranceConnectHelper
  def france_connect_enabled?(procedure: nil)
    return false if !FranceConnectService.enabled?

    procedure&.fc_particulier_validated? || Rails.application.secrets.france_connect_particulier.present?
  end
end
