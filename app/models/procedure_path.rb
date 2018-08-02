class ProcedurePath < ApplicationRecord
  validates :path, format: { with: /\A[a-z0-9_\-]{3,50}\z/ }, presence: true, allow_blank: false, allow_nil: false
  validates :administrateur_id, presence: true, allow_blank: false, allow_nil: false

  belongs_to :test_procedure, class_name: 'Procedure'
  belongs_to :procedure
  belongs_to :administrateur

  def self.find_with_procedure(procedure)
    where(procedure: procedure).or(where(test_procedure: procedure)).last
  end

  def self.find_with_path(path)
    left_outer_joins(:procedure, :test_procedure)
      .where("path LIKE ?", "%#{path}%")
      .order(:id)
  end

  def hide!(new_procedure)
    if procedure == new_procedure
      update!(procedure: nil)
    end
    if test_procedure == new_procedure
      update!(test_procedure: nil)
    end
  end

  def archive!
    update!(procedure: nil)
  end

  def publish_for_test!(new_procedure)
    if test_procedure != new_procedure
      if test_procedure.present?
        test_procedure.destroy
      end
      update!(test_procedure: new_procedure)
    end
  end

  def publish_test_procedure!
    publish!(test_procedure)
  end

  def publish!(new_procedure)
    if procedure != new_procedure
      if procedure&.publiee?
        procedure.archive!
      end

      if test_procedure == new_procedure
        update!(
          procedure: new_procedure,
          test_procedure: nil
        )
      else
        update!(procedure: new_procedure)
      end
    end
  end
end
