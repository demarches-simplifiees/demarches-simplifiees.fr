class Admin::InstructeursController < AdminController
  include SmartListing::Helper::ControllerExtensions
  helper SmartListing::Helper

  def index
    @instructeurs = smart_listing_create :instructeurs,
      current_administrateur.instructeurs,
      partial: "admin/instructeurs/list",
      array: true
  end

  def create
    email = params[:instructeur][:email].downcase
    @instructeur = Instructeur.by_email(email)
    procedure_id = params[:procedure_id]

    if @instructeur.nil?
      invite_instructeur(params[:instructeur][:email])
    else
      assign_instructeur!
    end

    if procedure_id.present?
      redirect_to admin_procedure_assigns_path(procedure_id: procedure_id)
    else
      redirect_to admin_instructeurs_path
    end
  end

  def destroy
    Instructeur.find(params[:id]).administrateurs.delete current_administrateur
    redirect_to admin_instructeurs_path
  end

  private

  def invite_instructeur(email)
    user = User.create_or_promote_to_instructeur(
      email,
      SecureRandom.hex,
      administrateurs: [current_administrateur]
    )

    if user.valid?
      user.invite!

      flash.notice = 'Instructeur ajouté'
    else
      flash.alert = user.errors.full_messages
    end
  end

  def assign_instructeur!
    if current_administrateur.instructeurs.include?(@instructeur)
      flash.alert = 'Instructeur déjà ajouté'
    else
      @instructeur.administrateurs.push current_administrateur
      flash.notice = 'Instructeur ajouté'
      # TODO Mailer no assign_to
    end
  end
end
