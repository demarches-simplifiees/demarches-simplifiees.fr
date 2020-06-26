class ProcedureRevision < ApplicationRecord
  belongs_to :procedure, -> { with_discarded }, inverse_of: :revisions

  has_many :revision_types_de_champ, -> { public_only.ordered }, class_name: 'ProcedureRevisionTypeDeChamp', foreign_key: :revision_id, dependent: :destroy, inverse_of: :revision
  has_many :revision_types_de_champ_private, -> { private_only.ordered }, class_name: 'ProcedureRevisionTypeDeChamp', foreign_key: :revision_id, dependent: :destroy, inverse_of: :revision
  has_many :types_de_champ, through: :revision_types_de_champ, source: :type_de_champ
  has_many :types_de_champ_private, through: :revision_types_de_champ_private, source: :type_de_champ

  def draft?
    procedure.draft_revision == self
  end

  def locked?
    !draft?
  end
end
