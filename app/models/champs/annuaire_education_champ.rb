# == Schema Information
#
# Table name: champs
#
#  id               :integer          not null, primary key
#  data             :jsonb
#  private          :boolean          default(FALSE), not null
#  row              :integer
#  type             :string
#  value            :string
#  created_at       :datetime
#  updated_at       :datetime
#  dossier_id       :integer
#  etablissement_id :integer
#  parent_id        :bigint
#  type_de_champ_id :integer
#
class Champs::AnnuaireEducationChamp < Champs::TextChamp
  before_save :cleanup_if_empty
  after_update_commit :fetch_data

  private

  def cleanup_if_empty
    if value_changed?
      self.data = nil
    end
  end

  def fetch_data
    if value.present? && data.nil?
      AnnuaireEducationUpdateJob.perform_later(self)
    end
  end
end
