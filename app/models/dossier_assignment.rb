# frozen_string_literal: true

class DossierAssignment < ApplicationRecord
  belongs_to :dossier

  belongs_to :groupe_instructeur, optional: true, inverse_of: :assignments
  belongs_to :previous_groupe_instructeur, class_name: 'GroupeInstructeur', optional: true, inverse_of: :previous_assignments

  enum :mode, {
    auto: 'auto',
    manual: 'manual',
    tech: 'tech'
  }

  scope :manual, -> { where(mode: :manual) }

  def groupe_instructeur_label
    @groupe_instructeur_label ||= groupe_instructeur&.label.presence || read_attribute(:groupe_instructeur_label)
  end

  def previous_groupe_instructeur_label
    @previous_groupe_instructeur_label ||= previous_groupe_instructeur&.label.presence || read_attribute(:previous_groupe_instructeur_label)
  end
end
