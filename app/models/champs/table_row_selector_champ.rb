# frozen_string_literal: true

class Champs::TableRowSelectorChamp < Champs::TextChamp
  def fetch_external_data?
    true
  end

  def fetch_external_data
    # APIEducation::AnnuaireEducationAdapter.new(external_id).to_params
    TableRowSelector::API.fetch_row(external_id)
  end

  def update_with_external_data!(data:)
    update!(data: data) if data&.is_a?(Hash)
  end
end
