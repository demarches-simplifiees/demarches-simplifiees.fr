# == Schema Information
#
# Table name: dossier_snapshots
#
#  id         :uuid             not null, primary key
#  data       :jsonb
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  dossier_id :bigint           not null
#
class DossierSnapshot < ApplicationRecord
  belongs_to :dossier

  before_create :serialize_dossier

  private

  def serialize_dossier
    self.data = SerializerService.dossier(dossier)
  end
end
