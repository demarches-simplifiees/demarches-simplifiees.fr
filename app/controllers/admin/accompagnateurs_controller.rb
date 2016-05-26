class Admin::AccompagnateursController < AdminController
  include SmartListing::Helper::ControllerExtensions
  helper SmartListing::Helper

  before_action :retrieve_procedure

  def show
    assign_scope = @procedure.gestionnaires
    @accompagnateurs_assign = smart_listing_create :accompagnateurs_assign,
                                                   assign_scope,
                                                   partial: "admin/accompagnateurs/list_assign",
                                                   array: true

    not_assign_scope = current_administrateur.gestionnaires.where.not(id: assign_scope.ids)
    not_assign_scope = not_assign_scope.where("email LIKE '%#{params[:filter]}%'") if params[:filter]

    @accompagnateurs_not_assign = smart_listing_create :accompagnateurs_not_assign,
                                                       not_assign_scope,
                                                       partial: "admin/accompagnateurs/list_not_assign",
                                                       array: true

    @gestionnaire ||= Gestionnaire.new
  end

  def update
    AccompagnateurService.change_assignement! Gestionnaire.find(params[:accompagnateur_id]), Procedure.find(params[:procedure_id]), params[:to]

    flash.notice = "Assignement effectué"
    redirect_to admin_procedure_accompagnateurs_path, procedure_id: params[:procedure_id]
  end
end