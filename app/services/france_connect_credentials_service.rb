class FranceConnectCredentialsService
  def call(procedure_url_path = nil)
    return {} unless Rails.configuration.x.france_connect.enabled

    procedure = procedure_by_url(procedure_url_path)

    if procedure&.fc_particulier_validated?
      { identifier: procedure.fc_particulier_id, secret: procedure.fc_particulier_secret }
    else
      Rails.application.secrets.france_connect_particulier
    end
  end

  private

  def procedure_by_url(procedure_url_path)
    return if procedure_url_path.nil?

    recognized_path = Rails.application.routes.recognize_path(procedure_url_path)
    Procedure.find_by(path: recognized_path[:path])
  rescue ActionController::RoutingError
    nil
  end
end
