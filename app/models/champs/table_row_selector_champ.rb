# frozen_string_literal: true

class Champs::TableRowSelectorChamp < Champs::TextChamp
  def fetch_external_data?
    true
  end

  def fetch_external_data
    # APIEducation::AnnuaireEducationAdapter.new(external_id).to_params
    # TODO build api for TableRowSelector
  end

  def update_with_external_data!(data:)
    if data&.is_a?(Hash)
      update!(
        data: data,
        value: data['Mes-Démarches'] || data.first.value
      )
    end
  end
end
