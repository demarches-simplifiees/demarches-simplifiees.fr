# frozen_string_literal: true

module ProcedurePathConcern
  extend ActiveSupport::Concern

  included do
    has_many :procedure_paths, dependent: :destroy, autosave: true

    after_initialize :ensure_path_exists
    before_validation :ensure_path_exists

    validates :procedure_paths, length: { minimum: 1 }

    scope :find_with_path, -> (path) do
      normalized_path = path.downcase.strip
      left_joins(:procedure_paths).where(procedure_paths: { path: normalized_path }).or(where(path: normalized_path)).limit(1)
      # TODO: remove the or(where(path: normalized_path)) when the migration is done
    end

    def ensure_path_exists
      uuid = SecureRandom.uuid
      if self.path.blank?
        self.path = uuid
      end
      if self.procedure_paths.empty?
        self.procedure_paths.build(path: uuid)
      end
    end

    def other_procedure_with_path(path)
      Procedure
        .where.not(id: self.id)
        .find_with_path(path).first
    end

    def path
      canonical_path || super
    end

    def canonical_path
      procedure_paths.by_updated_at.first&.path
    end

    def claim_path!(administrateur, new_path)
      claim_path(administrateur, new_path)
      raise ActiveRecord::RecordInvalid if errors.any?
    end

    def claim_path(administrateur, new_path)
      return if new_path.blank?

      procedure_path = procedure_paths.find { _1.path == new_path } || ProcedurePath.find_or_initialize_by(path: new_path)

      if procedure_path.procedure.present? && !administrateur.owns?(procedure_path.procedure)
        errors.add(:path, :taken)
      end

      procedure_path.updated_at = Time.zone.now

      procedure_paths << procedure_path
    end

    def path_available?(path)
      other_procedure_with_path(path).blank?
    end

    def path_customized?
      !path.match?(/[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}/)
    end

    def suggested_path
      if path_customized?
        return path
      end
      slug = libelle&.parameterize&.first(50)
      suggestion = slug
      counter = 1
      while !path_available?(suggestion)
        counter = counter + 1
        suggestion = "#{slug}-#{counter}"
      end
      suggestion
    end
  end
end
