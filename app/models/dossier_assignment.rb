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

  belongs_to :groupe_instructeur, optional: true, inverse_of: :assignments
  belongs_to :previous_groupe_instructeur, class_name: 'GroupeInstructeur', optional: true, inverse_of: :previous_assignments

  enum mode: {
    auto: 'auto',
    manual: 'manual'
  }
  scope :manual, -> { where(mode: :manual) }

  def groupe_instructeur_label
    @groupe_instructeur_label ||= groupe_instructeur&.label.presence || read_attribute(:groupe_instructeur_label)
  end

  def previous_groupe_instructeur_label
    @previous_groupe_instructeur_label ||= previous_groupe_instructeur&.label.presence || read_attribute(:previous_groupe_instructeur_label)
  end
end
