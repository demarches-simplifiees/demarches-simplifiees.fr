class Admin::InstructeursController < AdminController
  include SmartListing::Helper::ControllerExtensions
  helper SmartListing::Helper

  before_action :retrieve_procedure

  ASSIGN = 'assign'
  NOT_ASSIGN = 'not_assign'

  def show
    assign_scope = @procedure.gestionnaires

    @instructeurs_assign = smart_listing_create :instructeurs_assign,
      assign_scope,
      partial: "admin/instructeurs/list_assign",
      array: true

    not_assign_scope = current_administrateur.gestionnaires.where.not(id: assign_scope.ids)

    if params[:filter]
      not_assign_scope = not_assign_scope.where("email LIKE ?", "%#{params[:filter]}%")
    end

    @instructeurs_not_assign = smart_listing_create :instructeurs_not_assign,
      not_assign_scope,
      partial: "admin/instructeurs/list_not_assign",
      array: true

    @gestionnaire ||= Gestionnaire.new
  end

  def update
    gestionnaire = Gestionnaire.find(params[:instructeur_id])
    procedure = Procedure.find(params[:procedure_id])
    to = params[:to]

    case to
    when ASSIGN
      if gestionnaire.assign_to_procedure(procedure)
        flash.notice = "L'instructeur a bien été affecté"
      else
        flash.alert = "L'instructeur a déjà été affecté"
      end
    when NOT_ASSIGN
      if gestionnaire.remove_from_procedure(procedure)
        flash.notice = "L'instructeur a bien été désaffecté"
      else
        flash.alert = "L'instructeur a déjà été désaffecté"
      end
    end

    redirect_to admin_procedure_instructeurs_path, procedure_id: params[:procedure_id]
  end
end
