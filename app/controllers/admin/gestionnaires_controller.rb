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
    @gestionnaire = Gestionnaire.find_by_email(params[:gestionnaire][:email])
    procedure_id = params[:procedure_id]

    if @gestionnaire.nil?
      new_gestionnaire!
    else
      assign_gestionnaire!
    end

    return redirect_to admin_procedure_accompagnateurs_path(procedure_id: procedure_id) unless procedure_id.nil?
    redirect_to admin_gestionnaires_path
  end

  def destroy
    Gestionnaire.find(params[:id]).administrateurs.delete current_administrateur
    redirect_to admin_gestionnaires_path
  end


  def create_gestionnaire_params
    params.require(:gestionnaire).permit(:email)
        .merge(password: 'TPS2016BOOSTCAMP') #SecureRandom.hex(5)
        .merge(administrateurs: [current_administrateur])
  end

  private

  def new_gestionnaire!
    @gestionnaire = Gestionnaire.create(create_gestionnaire_params)

    if @gestionnaire.errors.messages.empty?
      flash.notice = 'Accompagnateur ajouté'
      GestionnaireMailer.new_gestionnaire(@gestionnaire.email, @gestionnaire.password).deliver_now!
      GestionnaireMailer.new_assignement(@gestionnaire.email, current_administrateur.email).deliver_now!
    else
      flash.alert = @gestionnaire.errors.full_messages.join('<br />').html_safe
    end
  end

  def assign_gestionnaire!
    if current_administrateur.gestionnaires.include? @gestionnaire
      flash.alert = 'Accompagnateur déjà ajouté'
    else
      GestionnaireMailer.new_assignement(@gestionnaire.email, current_administrateur.email).deliver_now!
      @gestionnaire.administrateurs.push current_administrateur
      flash.notice = 'Accompagnateur ajouté'
      #TODO Mailer no assign_to
    end
  end
end