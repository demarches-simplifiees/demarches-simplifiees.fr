class Gestionnaires::SessionsController < Sessions::SessionsController


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
