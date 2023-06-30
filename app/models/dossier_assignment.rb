# == Schema Information
#
# Table name: dossier_assignments
#
#  id                                :bigint           not null, primary key
#  assigned_at                       :datetime         not null
#  assigned_by                       :string
#  groupe_instructeur_label          :string
#  mode                              :string           not null
#  previous_groupe_instructeur_label :string
#  dossier_id                        :bigint           not null
#  groupe_instructeur_id             :bigint
#  previous_groupe_instructeur_id    :bigint
#
class DossierAssignment < ApplicationRecord
  belongs_to :dossier

  enum mode: {
    auto: 'auto',
    manual: 'manual'
  }
  scope :manual, -> { where(mode: :manual) }
end
