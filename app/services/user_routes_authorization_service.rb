class UserRoutesAuthorizationService

  def self.authorized_paths
    {
        root: '',
        carte: '/carte',
        description: '/description',
        recapitulatif: '/recapitulatif'
    }
  end

  def self.authorized_states
    Dossier.states
  end

  def self.authorized_routes
    {
        root: {
            authorized_states: [:draft],
            api_carto: false
        },
        carte: {
            authorized_states: [:draft, :initiated, :replied, :updated],
            api_carto: true
        },
        description: {
            authorized_states: [:draft, :initiated, :replied, :updated],
            api_carto: false
        },
        recapitulatif: {
            authorized_states: [:initiated, :replied, :updated, :validated, :submitted, :closed],
            api_carto: false
        }
    }
  end

  def self.authorized_route? path, state, api_carto=false
    return raise 'Not a valid path' unless authorized_paths.has_value? path
    return raise 'Not a valid state' unless authorized_states.has_value? state

    path_key = authorized_paths.key(path)

    first = authorized_routes[path_key][:authorized_states].include? state.to_sym
    seconde = authorized_routes[path_key][:api_carto] ? api_carto : true

    first && seconde
  end
end