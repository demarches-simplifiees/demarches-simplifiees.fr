# == Schema Information
#
# Table name: dossier_corrections
#
#  id             :bigint           not null, primary key
#  reason         :string           default("incorrect"), not null
#  resolved_at    :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  commentaire_id :bigint
#  dossier_id     :bigint           not null
#
class DossierCorrection < ApplicationRecord
  belongs_to :dossier
  belongs_to :commentaire

  self.ignored_columns += ['kind']

  validates_associated :commentaire

  scope :pending, -> { where(resolved_at: nil) }

  enum reason: { incorrect: 'incorrect', incomplete: 'incomplete' }, _prefix: :dossier

  def resolved?
    resolved_at.present?
  end
end
