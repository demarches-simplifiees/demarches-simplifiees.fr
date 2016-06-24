class ProcedurePath < ActiveRecord::Base
  validates :path, procedure_path_format: true, presence: true, allow_blank: false, allow_nil: false
  validates :administrateur_id, presence: true, allow_blank: false, allow_nil: false
  validates :procedure_id, presence: true, allow_blank: false, allow_nil: false

  belongs_to :procedure
  belongs_to :administrateur
end