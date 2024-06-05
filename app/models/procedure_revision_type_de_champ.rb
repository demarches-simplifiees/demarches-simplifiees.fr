class ProcedureRevisionTypeDeChamp < ApplicationRecord
  belongs_to :revision, class_name: 'ProcedureRevision'
  belongs_to :type_de_champ

  belongs_to :parent, class_name: 'ProcedureRevisionTypeDeChamp', optional: true
  has_many :revision_types_de_champ, -> { ordered }, foreign_key: :parent_id, class_name: 'ProcedureRevisionTypeDeChamp', inverse_of: :parent, dependent: :destroy
  has_one :procedure, through: :revision
  scope :root, -> { where(parent: nil) }
  scope :ordered, -> { order(:position, :id) }
  scope :revision_ordered, -> { order(:revision_id) }
  scope :public_only, -> { joins(:type_de_champ).where(types_de_champ: { private: false }) }
  scope :private_only, -> { joins(:type_de_champ).where(types_de_champ: { private: true }) }

  delegate :stable_id, :libelle, :description, :type_champ, :mandatory?, :private?, :to_typed_id, to: :type_de_champ

  def child?
    parent_id.present?
  end

  def first?
    position == 0
  end

  def last?
    siblings.last == self
  end

  def empty?
    revision_types_de_champ.empty?
  end

  def siblings
    if parent_id.present?
      revision.revision_types_de_champ.where(parent_id: parent_id).ordered
    elsif private?
      revision.revision_types_de_champ_private
    else
      revision.revision_types_de_champ_public
    end
  end

  def upper_coordinates
    upper = siblings.filter { |s| s.position < position }

    if child?
      upper += parent.upper_coordinates
    end

    if type_de_champ.private?
      upper += revision.revision_types_de_champ_public
    end

    upper
  end

  def siblings_starting_at(offset)
    siblings.filter { |s| (position + offset) <= s.position }
  end

  def previous_sibling
    index = siblings.index(self)
    if index > 0
      siblings[index - 1]
    end
  end

  def block
    if child?
      parent
    else
      revision
    end
  end

  def used_by_routing_rules?
    stable_id.in?(procedure.stable_ids_used_by_routing_rules)
  end

  def used_by_ineligibilite_rules?
    revision.ineligibilite_enabled? && stable_id.in?(revision.ineligibilite_rules&.sources || [])
  end
end
