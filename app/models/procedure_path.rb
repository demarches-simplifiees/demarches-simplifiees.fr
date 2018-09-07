class ProcedurePath < ApplicationRecord
  validates :path, format: { with: /\A[a-z0-9_\-]{3,50}\z/ }, presence: true, allow_blank: false, allow_nil: false
  validates :administrateur_id, presence: true, allow_blank: false, allow_nil: false
  validates :procedure_id, presence: true, allow_blank: false, allow_nil: false

  belongs_to :procedure
  belongs_to :administrateur

  def self.valid?(procedure, path)
    create_with(procedure: procedure, administrateur: procedure.administrateur)
      .find_or_initialize_by(path: path).validate
  end

  def self.find_with_path(path)
    joins(:procedure)
      .where.not(procedures: { aasm_state: :archivee })
      .where("path LIKE ?", "%#{path}%")
      .order(:id)
  end

  def hide!
    destroy!
  end

  def publish!(new_procedure)
    if procedure&.publiee? && procedure != new_procedure
      procedure.archive!
    end
    update!(procedure: new_procedure)
  end
end
