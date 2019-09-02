class Admin::AssignsController < AdminController
  include SmartListing::Helper::ControllerExtensions
  helper SmartListing::Helper

  before_action :retrieve_procedure

  ASSIGN = 'assign'
  NOT_ASSIGN = 'not_assign'

  def show
    assign_scope = @procedure.defaut_groupe_instructeur.instructeurs

    @instructeurs_assign = smart_listing_create :instructeurs_assign,
      assign_scope,
      partial: "admin/assigns/list_assign",
      array: true

    not_assign_scope = current_administrateur.instructeurs.where.not(id: assign_scope.ids)

    if params[:filter]
      not_assign_scope = not_assign_scope.where("email LIKE ?", "%#{params[:filter]}%")
    end

    @instructeurs_not_assign = smart_listing_create :instructeurs_not_assign,
      not_assign_scope,
      partial: "admin/assigns/list_not_assign",
      array: true

    @instructeur ||= Instructeur.new
  end

  def update
    instructeur = Instructeur.find(params[:instructeur_id])
    procedure = Procedure.find(params[:procedure_id])
    to = params[:to]

    case to
    when ASSIGN
      if instructeur.assign_to_procedure(procedure)
        flash.notice = "L'instructeur a bien été affecté"
      else
        flash.alert = "L'instructeur a déjà été affecté"
      end
    when NOT_ASSIGN
      if instructeur.remove_from_procedure(procedure)
        flash.notice = "L'instructeur a bien été désaffecté"
      else
        flash.alert = "L'instructeur a déjà été désaffecté"
      end
    end

    redirect_to admin_procedure_assigns_path, procedure_id: params[:procedure_id]
  end
end
