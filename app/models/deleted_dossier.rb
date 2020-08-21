# == Schema Information
#
# Table name: deleted_dossiers
#
#  id           :bigint           not null, primary key
#  deleted_at   :datetime
#  reason       :string
#  state        :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  dossier_id   :bigint
#  procedure_id :bigint
#
class DeletedDossier < ApplicationRecord
  belongs_to :procedure, -> { with_discarded }, inverse_of: :deleted_dossiers

  validates :dossier_id, uniqueness: true

  enum reason: {
    user_request:      'user_request',
    manager_request:   'manager_request',
    user_removed:      'user_removed',
    procedure_removed: 'procedure_removed',
    expired:           'expired'
  }

  def self.create_from_dossier(dossier, reason)
    create!(
      reason: reasons.fetch(reason),
      dossier_id: dossier.id,
      procedure: dossier.procedure,
      state: dossier.state,
      deleted_at: Time.zone.now
    )
  end

  def procedure_removed?
    reason == self.class.reasons.fetch(:procedure_removed)
  end
end
