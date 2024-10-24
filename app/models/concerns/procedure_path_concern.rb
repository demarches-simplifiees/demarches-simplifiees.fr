# frozen_string_literal: true

module ProcedurePathConcern
  extend ActiveSupport::Concern

  included do
    has_many :procedure_paths, dependent: :destroy, autosave: true

    validates :path, presence: true, format: { with: /\A[a-z0-9_\-]{3,200}\z/ }, uniqueness: { scope: [:path, :closed_at, :hidden_at, :unpublished_at], case_sensitive: false }

    after_initialize :ensure_path_exists
    before_validation :ensure_path_exists
    before_validation :sync_procedure_path, if: :path_changed?

    validates :procedure_paths, length: { minimum: 1 }
    # validates :procedure_paths, length: { minimum: 2 }, on: :publication

    scope :find_with_path, -> (path) { joins(:procedure_paths).where(procedure_paths: { path: }).limit(1) }

    def ensure_path_exists
      if self.path.blank?
        self.path = SecureRandom.uuid
      end
    end

    def sync_procedure_path
      if path.blank?
        if procedure_paths.empty?
          procedure_paths.build(path: SecureRandom.uuid)
        end

        return
      end

      procedure_path = procedure_paths.find { _1.path == path } || ProcedurePath.find_or_initialize_by(path: path)

      if procedure_path.procedure && procedure_path.procedure != self
        procedure_path.procedure.update!(path: SecureRandom.uuid)
      end
      procedure_path.updated_at = Time.zone.now

      procedure_paths << procedure_path
    end

    def other_procedure_with_path(path)
      Procedure.publiees
        .where.not(id: self.id)
        .find_with_path(path).first
    end

    def claim_path!(administrateur, path)
      return if path.blank?

      procedure_path = ProcedurePath.find_by(path: path)

      errors.add(:procedure_paths, :path_not_available_for_claim) if !administrateur.owns?(procedure_path.procedure)

      procedure_path.update!(procedure: self)
    end

    def canonical_path
      procedure_paths.by_updated_at.first.path
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
