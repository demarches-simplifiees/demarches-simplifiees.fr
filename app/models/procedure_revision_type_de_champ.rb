class ProcedureRevisionTypeDeChamp < ApplicationRecord
  belongs_to :procedure_revision
  belongs_to :type_de_champ

  scope :ordered, -> { order(:position) }
  scope :public_only, -> { joins(:type_de_champ).where(types_de_champ: { private: false }) }
  scope :private_only, -> { joins(:type_de_champ).where(types_de_champ: { private: true }) }

  before_create :set_position

  def private?
    type_de_champ.private?
  end

  private

  def set_position
    self.position ||= if private?
      procedure_revision.types_de_champ_private.size + 1
    else
      procedure_revision.types_de_champ.size + 1
    end
  end
end
