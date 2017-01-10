class OpensimplifController < Backoffice::Dossiers::ProcedureController
  def index
    if params[:id].nil?
      procedure = current_gestionnaire.procedures.order('libelle ASC').first

      if procedure.nil?
        return redirect_to simplifications_nothing_path
      else
        return redirect_to simplification_path(id: procedure.id)
      end
    end

    smartlisting_dossier
  end

  def nothing

  end

  def reload_smartlisting
    smartlisting_dossier

    render 'opensimplif/index', formats: :js
  end

  private

  def smartlisting_dossier dossiers_list=nil, liste='all_state'
    dossiers_list_facade liste

    mes_dossiers_list = current_user.dossiers
    follow_dossiers_list = dossiers_list_facade.service.suivi
    all_state_dossiers_list = dossiers_list_facade.service.all_state

    if param_page.nil?
      params[:dossiers_smart_listing] = {page: dossiers_list_facade.service.default_page}
    end

    smart_listing_create :mes_dossiers,
                         mes_dossiers_list,
                         partial: "backoffice/dossiers/list",
                         array: true,
                         default_sort: dossiers_list_facade.service.default_sort

    smart_listing_create :follow_dossiers,
                         follow_dossiers_list,
                         partial: "backoffice/dossiers/list",
                         array: true,
                         default_sort: dossiers_list_facade.service.default_sort

    smart_listing_create :all_state_dossiers,
                         all_state_dossiers_list,
                         partial: "backoffice/dossiers/list",
                         array: true,
                         default_sort: dossiers_list_facade.service.default_sort
  end

  def dossiers_list_facade liste='all_state'
    @facade_data_view ||= DossiersListFacades.new current_gestionnaire, liste, retrieve_procedure
  end
end
