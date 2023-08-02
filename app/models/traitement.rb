class Traitement < ApplicationRecord
  belongs_to :dossier, optional: false

  scope :en_construction, -> { where(state: Dossier.states.fetch(:en_construction)) }
  scope :en_instruction, -> { where(state: Dossier.states.fetch(:en_instruction)) }
  scope :termine, -> { where(state: Dossier::TERMINE) }

  scope :for_traitement_time_stats, -> (procedure) do
    includes(:dossier)
      .termine
      .where(dossier: procedure.dossiers.visible_by_administration)
      .where.not('dossiers.depose_at' => nil)
      .where.not(processed_at: nil)
      .order(:processed_at)
  end
end
