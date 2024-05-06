class EditableChamp::CarteComponent < EditableChamp::EditableChampBaseComponent
  include ApplicationHelper
  def dsfr_champ_container
    :fieldset
  end

  def react_props
    {
      feature_collection: @champ.to_feature_collection,
      champ_id: @champ.input_id,
      url: update_path,
      adresse_source: data_sources_data_source_adresse_path,
      options: @champ.render_options
    }
  end

  def update_path
    champs_carte_features_path(@champ.dossier, @champ.stable_id, row_id: @champ.row_id)
  end
end
