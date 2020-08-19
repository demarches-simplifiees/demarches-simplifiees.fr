# == Schema Information
#
# Table name: procedure_revision_types_de_champ
#
#  id               :bigint           not null, primary key
#  position         :integer          not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  revision_id      :bigint           not null
#  type_de_champ_id :bigint           not null
#
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
      if revision.types_de_champ_private.present?
        revision.revision_types_de_champ_private.filter(&:persisted?).last.position + 1
      else
        0
      end
    else
      if revision.types_de_champ.present?
        revision.revision_types_de_champ.filter(&:persisted?).last.position + 1
      else
        0
      end
    end
  end
end
