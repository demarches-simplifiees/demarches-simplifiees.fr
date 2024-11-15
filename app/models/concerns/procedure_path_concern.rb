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

    def update_procedure_path
      return if path_before_last_save == path

      procedure_paths.where(path: path_before_last_save).destroy_all

      if procedure_paths.where(path: path).empty?
        procedure_paths.create!(path: path)
      end
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
