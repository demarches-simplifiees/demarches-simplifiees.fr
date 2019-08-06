class Admin::InstructeursController < AdminController
  include SmartListing::Helper::ControllerExtensions
  helper SmartListing::Helper

  def index
    @instructeurs = smart_listing_create :instructeurs,
      current_administrateur.instructeurs,
      partial: "admin/instructeurs/list",
      array: true

    @instructeur ||= Instructeur.new
  end

  def create
    email = params[:instructeur][:email].downcase
    @instructeur = Instructeur.find_by(email: email)
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
    password = SecureRandom.hex

    @instructeur = Instructeur.create(
      email: email,
      password: password,
      password_confirmation: password,
      administrateurs: [current_administrateur]
    )

    if @instructeur.errors.messages.empty?
      @instructeur.invite!

      if User.exists?(email: @instructeur.email)
        InstructeurMailer.user_to_instructeur(@instructeur.email).deliver_later
      else
        User.create(email: email, password: password, confirmed_at: Time.zone.now)
      end
      flash.notice = 'Instructeur ajouté'
    else
      flash.alert = @instructeur.errors.full_messages
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
