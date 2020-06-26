class ProcedureRevisionTypeDeChamp < ApplicationRecord
  belongs_to :revision, class_name: 'ProcedureRevision'
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
      revision.types_de_champ_private.size
    else
      revision.types_de_champ.size
    end
  end
end
