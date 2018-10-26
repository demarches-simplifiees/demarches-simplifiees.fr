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
    email = params[:gestionnaire][:email].downcase
    @gestionnaire = Gestionnaire.find_by(email: email)
    procedure_id = params[:procedure_id]

    if @gestionnaire.nil?
      invite_gestionnaire(params[:gestionnaire][:email])
    else
      assign_gestionnaire!
    end

    if procedure_id.present?
      redirect_to admin_procedure_instructeurs_path(procedure_id: procedure_id)
    else
      redirect_to admin_gestionnaires_path
    end
  end

  def destroy
    Gestionnaire.find(params[:id]).administrateurs.delete current_administrateur
    redirect_to admin_gestionnaires_path
  end

  private

  def invite_gestionnaire(email)
    password = SecureRandom.hex

    @gestionnaire = Gestionnaire.create(
      email: email,
      password: password,
      password_confirmation: password,
      administrateurs: [current_administrateur]
    )

    if @gestionnaire.errors.messages.empty?
      @gestionnaire.invite!

      if User.exists?(email: @gestionnaire.email)
        GestionnaireMailer.user_to_gestionnaire(@gestionnaire.email).deliver_later
      else
        User.create(email: email, password: password, confirmed_at: Time.zone.now)
      end
      flash.notice = 'Instructeur ajouté'
    else
      flash.alert = @gestionnaire.errors.full_messages
    end
  end

  def assign_gestionnaire!
    if current_administrateur.gestionnaires.include? @gestionnaire
      flash.alert = 'Instructeur déjà ajouté'
    else
      @gestionnaire.administrateurs.push current_administrateur
      flash.notice = 'Instructeur ajouté'
      # TODO Mailer no assign_to
    end
  end
end
