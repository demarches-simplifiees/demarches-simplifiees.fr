class ProcedurePath < ApplicationRecord
  validates :path, format: { with: /\A[a-z0-9_\-]{3,50}\z/ }, presence: true, allow_blank: false, allow_nil: false
  validates :administrateur_id, presence: true, allow_blank: false, allow_nil: false
  validates :procedure_id, presence: true, allow_blank: false, allow_nil: false

  belongs_to :test_procedure, class_name: 'Procedure'
  belongs_to :procedure
  belongs_to :administrateur
end
