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
    description = "Allez voir le super site : #{APPLICATION_BASE_URL}"

    all_champs = TypeDeChamp.type_champs
      .map.with_index { |(name, _), i| TypeDeChamp.new(type_champ: name, private: false, libelle: name.humanize, description:, mandatory: true, stable_id: i) }
      .map.with_index { |type_de_champ, i| type_de_champ.champ.build(id: i) }

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

    all_champs
      .filter { |champ| champ.type_champ == TypeDeChamp.type_champs.fetch(:repetition) }
      .each do |champ_repetition|
        libelles = ['Prénom', 'Nom'];
        champ_repetition.champs << libelles.map.with_index do |libelle, i|
          text_tdc = TypeDeChamp.new(type_champ: :text, private: false, libelle: libelle, description: description, mandatory: true)
          text_tdc.champ.build(id: all_champs.length + i)
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

    @dossier = Dossier.new(champs: all_champs)
    @dossier.association(:procedure).target = Procedure.new
    all_champs.each do |champ|
      champ.association(:dossier).target = @dossier
      champ.champs.each do |champ|
        champ.association(:dossier).target = @dossier
      end
    end

    draft_revision = @dossier.procedure.build_draft_revision(types_de_champ: all_champs.map(&:type_de_champ))
    @dossier.association(:revision).target = draft_revision
    @dossier.champs_public.map(&:type_de_champ).map do |tdc|
      tdc.association(:revision_type_de_champ).target = tdc.build_revision_type_de_champ(revision: draft_revision)
      tdc.association(:revision).target = draft_revision
    end
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
