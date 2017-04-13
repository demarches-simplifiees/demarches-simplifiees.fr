class UserRoutesAuthorizationService

  def self.authorized_route? controller, dossier
    auth = controller.route_authorization

    auth[:states].include?(dossier.state.to_sym) &&
        (auth[:api_carto].nil? ? true : auth[:api_carto] == dossier.procedure.use_api_carto)
  end
end
