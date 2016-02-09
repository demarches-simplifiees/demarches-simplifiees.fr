class Admin::GestionnairesController < AdminController
  include SmartListing::Helper::ControllerExtensions
  helper SmartListing::Helper

  def index
    @gestionnaires = smart_listing_create :gestionnaires,
                     current_administrateur.gestionnaires,
                     partial: "admin/gestionnaires/list",
                     array: true
    @gestionnaire ||= Gestionnaire.new
  end


  def create
    gestionnaire_params = create_gestionnaire_params
    @gestionnaire = Gestionnaire.create(gestionnaire_params)

    if @gestionnaire.errors.messages.empty?
      flash.notice = 'Gestionnaire ajouté'
      GestionnaireMailer.new_gestionnaire(gestionnaire_params[:email], gestionnaire_params[:password]).deliver_now!
    else
      flash.alert = @gestionnaire.errors.full_messages.join('<br />').html_safe
    end

    redirect_to admin_gestionnaires_path
  end


  def destroy
    Gestionnaire.find(params[:id]).destroy
    redirect_to admin_gestionnaires_path
  end


  def create_gestionnaire_params
    params.require(:gestionnaire).permit(:email)
                                 .merge(administrateur_id: current_administrateur.id)
                                 .merge(password: SecureRandom.hex(5))
  end

end