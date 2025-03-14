# frozen_string_literal: true

module ProcedurePathConcern
  extend ActiveSupport::Concern

  included do
    self.ignored_columns += [:path]

    has_many :procedure_paths, -> { order(updated_at: :asc) }, inverse_of: :procedure, dependent: :destroy, autosave: true

    before_validation :ensure_path_exists

    validates :procedure_paths, length: { minimum: 1 }

    scope :find_with_path, -> (path) do
      normalized_path = path.downcase.strip
      left_joins(:procedure_paths).where(procedure_paths: { path: normalized_path }).limit(1)
    end

    def path = canonical_path

    def ensure_path_exists
      if self.procedure_paths.empty?
        uuid = SecureRandom.uuid
        self.procedure_paths.build(path: uuid)
      end
    end

    def other_procedure_with_path(path)
      Procedure
        .where.not(id: self.id)
        .find_with_path(path).first
    end

    def canonical_path
      procedure_paths.last&.path
    end

    def claim_path!(administrateur, new_path)
      return if new_path.blank?

      other_procedure = other_procedure_with_path(new_path)
      if other_procedure.present?
        if !administrateur.owns?(other_procedure)
          errors.add(:path, :taken)
        elsif other_procedure.procedure_paths.count == 1
          errors.add(:path, :last_path)
        end
        raise ActiveRecord::RecordInvalid if errors.any?
      end

      procedure_path = procedure_paths.find { _1.path == new_path } || ProcedurePath.find_or_initialize_by(path: new_path)

      procedure_path.updated_at = Time.zone.now

      procedure_paths << procedure_path
    end

    def path_available?(path)
      other_procedure_with_path(path).blank?
    end

    def previous_paths
      procedure_paths.reject { |path| path.path == self.path || path.uuid_path? }
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
