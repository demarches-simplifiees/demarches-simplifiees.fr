class UserRoutesAuthorizationService
  def self.authorized_route?(controller, dossier)
    auth = controller.route_authorization

    auth[:states].include?(dossier.state) &&
        (auth[:api_carto].nil? ? true : auth[:api_carto] == dossier.use_legacy_carto?)
  end
end
