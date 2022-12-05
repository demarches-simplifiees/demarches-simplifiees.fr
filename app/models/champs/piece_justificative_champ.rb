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
#  dossier_id                     :integer
#  etablissement_id               :integer
#  external_id                    :string
#  parent_id                      :bigint
#  type_de_champ_id               :integer
#
class Champs::PieceJustificativeChamp < Champ
  FILE_MAX_SIZE = 200.megabytes

  validates :piece_justificative_file,
    size: { less_than: FILE_MAX_SIZE },
    if: -> { !type_de_champ.skip_pj_validation }

  validates :piece_justificative_file,
    content_type: AUTHORIZED_CONTENT_TYPES,
    if: -> { !type_de_champ.skip_content_type_pj_validation }

  def main_value_name
    :piece_justificative_file
  end

  def search_terms
    # We don’t know how to search inside documents yet
  end

  def mandatory_blank?
    mandatory? && !piece_justificative_file.attached?
  end

  def for_export
    piece_justificative_file.map { _1.filename.to_s }
  end

  def for_api
    return nil unless piece_justificative_file.attached?

    piece_justificative_file.filter_map do |attachment|
      if attachment.virus_scanner.safe? || attachment.virus_scanner.pending?
        attachment.service_url
      end
    end
  end
end
