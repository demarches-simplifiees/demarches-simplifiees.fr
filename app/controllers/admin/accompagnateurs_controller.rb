class Admin::AccompagnateursController < AdminController
  include SmartListing::Helper::ControllerExtensions
  helper SmartListing::Helper

  before_action :retrieve_procedure

  ASSIGN = 'assign'
  NOT_ASSIGN = 'not_assign'

  def show
    assign_scope = @procedure.gestionnaires

    # FIXME: remove this comment (no code to remove) when
    # https://github.com/Sology/smart_listing/issues/134
    # is fixed.
    #
    # No need to permit parameters for smart_listing, because
    # there are no sortable columns
    #
    # END OF FIXME

    @accompagnateurs_assign = smart_listing_create :accompagnateurs_assign,
      assign_scope,
      partial: "admin/accompagnateurs/list_assign",
      array: true

    not_assign_scope = current_administrateur.gestionnaires.where.not(id: assign_scope.ids)
    not_assign_scope = not_assign_scope.where("email LIKE ?", "%#{params[:filter]}%") if params[:filter]

    # FIXME: remove this comment (no code to remove) when
    # https://github.com/Sology/smart_listing/issues/134
    # is fixed.
    #
    # No need to permit parameters for smart_listing, because
    # there are no sortable columns
    #
    # END OF FIXME

    @accompagnateurs_not_assign = smart_listing_create :accompagnateurs_not_assign,
      not_assign_scope,
      partial: "admin/accompagnateurs/list_not_assign",
      array: true

    @gestionnaire ||= Gestionnaire.new
  end

  def update
    gestionnaire = Gestionnaire.find(params[:accompagnateur_id])
    procedure = Procedure.find(params[:procedure_id])
    to = params[:to]

    case to
    when ASSIGN
      if gestionnaire.assign_to_procedure(procedure)
        flash.notice = "L'accompagnateur a bien été affecté"
      else
        flash.alert = "L'accompagnateur a déjà été affecté"
      end
    when NOT_ASSIGN
      if gestionnaire.remove_from_procedure(procedure)
        flash.notice = "L'accompagnateur a bien été désaffecté"
      else
        flash.alert = "L'accompagnateur a déjà été désaffecté"
      end
    end

    redirect_to admin_procedure_accompagnateurs_path, procedure_id: params[:procedure_id]
  end
end
