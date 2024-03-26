class RootController < ApplicationController
  include ApplicationHelper

  def index
    if administrateur_signed_in?
      return redirect_to admin_procedures_path
    elsif instructeur_signed_in?
      return redirect_to instructeur_procedures_path
    elsif expert_signed_in?
      return redirect_to expert_all_avis_path
    elsif user_signed_in?
      return redirect_to dossiers_path
    elsif super_admin_signed_in?
      return redirect_to manager_root_path
    end

    @stat = Stat.first

    render 'landing'
  end

  def administration
  end

  def patron
    description = "Allez voir le super site : #{Current.application_base_url}"

    procedure = Procedure.new
    revision = ProcedureRevision.new(procedure:)
    @dossier = Dossier.new(revision:, champs: [])
    @dossier.association(:procedure).target = procedure
    revision.association(:revision_types_de_champ).target = []
    revision.association(:types_de_champ).target = []
    revision.association(:types_de_champ_public).target = []

    id = 1
    all_champs = TypeDeChamp.type_champs
      .flat_map do |(type_champ, _)|
        stable_id = id += 1
        tdc = TypeDeChamp.new(type_champ:, private: false, libelle: type_champ.humanize, description:, mandatory: true, stable_id:)
        rtdc = ProcedureRevisionTypeDeChamp.new(revision:, type_de_champ: tdc)
        tdcs = [tdc]
        rtdcs = [rtdc]
        champs = [tdc.build_champ(id: id += 1, stable_id:, dossier: @dossier)]

        # if tdc.repetition?
        #   libelles = ['Prénom', 'Nom'];
        #   libelles.map do |libelle|
        #     stable_id = id += 1
        #     child_tdc = TypeDeChamp.new(type_champ: :text, private: false, libelle:, description:, mandatory: true, stable_id:)
        #     tdcs << child_tdc
        #     rtdcs << ProcedureRevisionTypeDeChamp.new(revision:, type_de_champ: child_tdc, parent: rtdc)
        #     champs << child_tdc.build_champ(id: id += 1, stable_id:, dossier: @dossier)
        #   end
        # end
        revision.association(:revision_types_de_champ).target += rtdcs
        revision.association(:types_de_champ).target += tdcs
        revision.association(:types_de_champ_public).target += tdcs

        champs
      end

    all_champs
      .filter { |champ| champ.type_champ == TypeDeChamp.type_champs.fetch(:header_section) }
      .each { |champ| champ.type_de_champ.libelle = 'Un super titre de section' }

    all_champs
      .filter { |champ| champ.type_de_champ.drop_down_list? }
      .each do |champ|
        if champ.type_de_champ.linked_drop_down_list?
          champ.type_de_champ.drop_down_list_value =
            "-- section 1 --
            option A
            option B
-- section 2 --
            option C"
        else
          champ.type_de_champ.drop_down_list_value =
            "option A
            option B
-- avant l'option C --
            option C"
          champ.value = '["option B", "option C"]'
          champ.type_de_champ.drop_down_other = "1"
        end
      end

    type_champ_values = {
      TypeDeChamp.type_champs.fetch(:date)      => '2016-07-26',
      TypeDeChamp.type_champs.fetch(:datetime)  => '26/07/2016 07:35',
      TypeDeChamp.type_champs.fetch(:textarea)  => 'Une description de mon projet'
    }

    type_champ_values.each do |(type_champ, value)|
      all_champs
        .filter { |champ| champ.type_champ == type_champ }
        .each { |champ| champ.value = value }
    end

    @dossier.association(:champs).target = all_champs
  end

  def suivi
  end

  def dismiss_outdated_browser
    dismiss_outdated_browser_banner

    respond_to do |format|
      format.html { redirect_back(fallback_location: root_path) }
      format.turbo_stream
    end
  end

  def save_locale
    set_locale(params[:locale])
    redirect_back(fallback_location: root_path)
  end
end
