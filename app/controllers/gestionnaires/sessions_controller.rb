class Gestionnaires::SessionsController < Sessions::SessionsController
  def demo
    @gestionnaire = Gestionnaire.new(email: 'gestionnaire@apientreprise.fr', password: 'password')
    render 'new'
  end

  def new
    @gestionnaire = Gestionnaire.new
  end

  def create
    super
  end

  def after_sign_in_path_for(resource)
    # stored_location_for(resource) ||
    backoffice_path
  end
end
