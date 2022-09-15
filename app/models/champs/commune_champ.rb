# == Schema Information
#
# Table name: champs
#
#  id                             :integer          not null, primary key
#  data                           :jsonb
#  fetch_external_data_exceptions :string           is an Array
#  private                        :boolean          default(FALSE), not null
#  rebased_at                     :datetime
#  row                            :integer
#  type                           :string
#  value                          :string
#  value_json                     :jsonb
#  created_at                     :datetime
#  updated_at                     :datetime
#  dossier_id                     :integer          not null
#  etablissement_id               :integer
#  external_id                    :string
#  parent_id                      :bigint
#  type_de_champ_id               :integer          not null
#
class Champs::CommuneChamp < Champs::TextChamp
  store_accessor :value_json, :departement, :code_departement

  def for_export
    [value, external_id, departement? ? departement_code_and_name : '']
  end

  def name_departement
    # FIXME we originaly saved already formatted departement with the code in the name
    departement&.gsub(/^(.[0-9])\s-\s/, '')
  end

  def departement_code_and_name
    "#{code_departement} - #{name_departement}"
  end

  def departement?
    departement.present?
  end

  def code?
    code.present?
  end

  def code
    external_id
  end
end
