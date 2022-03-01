# == Schema Information
#
# Table name: procedure_revision_types_de_champ
#
#  id               :bigint           not null, primary key
#  position         :integer          not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  parent_id        :bigint
#  revision_id      :bigint           not null
#  type_de_champ_id :bigint           not null
#
class ProcedureRevisionTypeDeChamp < ApplicationRecord
  belongs_to :revision, class_name: 'ProcedureRevision'
  belongs_to :type_de_champ

  belongs_to :parent, class_name: 'ProcedureRevisionTypeDeChamp', optional: true
  has_many :revision_types_de_champ, -> { ordered }, foreign_key: :parent_id, class_name: 'ProcedureRevisionTypeDeChamp', inverse_of: :parent, dependent: :destroy
  has_many :types_de_champ, through: :revision_types_de_champ, source: :type_de_champ

  scope :root, -> { where(parent: nil) }
  scope :ordered, -> { order(:position) }
  scope :parent_ordered, -> { order(:parent_id, :position) }
  scope :public_only, -> { joins(:type_de_champ).where(types_de_champ: { private: false }) }
  scope :private_only, -> { joins(:type_de_champ).where(types_de_champ: { private: true }) }

  delegate :stable_id, :libelle, :private?, to: :type_de_champ

  before_create :set_position

  def child?
    parent_id.present?
  end

  private

  def set_position
    self.position ||= begin
      revision_types_de_champ = if child?
        parent.revision_types_de_champ
      elsif private?
        revision.revision_types_de_champ_private
      else
        revision.revision_types_de_champ
      end.filter(&:persisted?)

      if revision_types_de_champ.present?
        revision_types_de_champ.last.position + 1
      else
        0
      end
    end
  end
end
