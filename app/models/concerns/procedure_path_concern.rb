# frozen_string_literal: true

module ProcedurePathConcern
  extend ActiveSupport::Concern

  included do
    has_many :procedure_paths, dependent: :destroy

    validates :path, presence: true, format: { with: /\A[a-z0-9_\-]{3,200}\z/ }, uniqueness: { scope: [:path, :closed_at, :hidden_at, :unpublished_at], case_sensitive: false }

    after_initialize :ensure_path_exists
    before_save :ensure_path_exists
    after_save :update_procedure_path

    def ensure_path_exists
      if self.path.blank?
        self.path = SecureRandom.uuid
      end
    end

    def deactivate_all_paths
      procedure_paths.update_all(deactivated_at: Time.zone.now)
    end

    def update_procedure_path
      if !publiee?
        deactivate_all_paths
      end

      return if path_before_last_save == path

      procedure_paths.find_by(path: path_before_last_save)&.destroy! if brouillon?

      # disable previous active paths
      ProcedurePath.find_by(path: path, deactivated_at: nil)&.update!(deactivated_at: Time.zone.now)

      procedure_paths.find_or_create_by(path: path).update!(deactivated_at: publiee? ? nil : Time.zone.now)
    end

    def other_procedure_with_path(path)
      Procedure.publiees
        .where.not(id: self.id)
        .find_by(path: path)
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
