# frozen_string_literal: true

class Champs::AnnuaireEducationChamp < Champs::TextChamp
  def fetch_external_data?
    true
  end

  def fetch_external_data
    APIEducation::AnnuaireEducationAdapter.new(external_id).to_params
  end

  def selected_items
    if external_id.present?
      [{ value: external_id, label: value }]
    else
      []
    end
  end
end
