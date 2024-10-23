# frozen_string_literal: true

module ProcedurePathConcern
  extend ActiveSupport::Concern

  included do
    has_many :procedure_paths, dependent: :destroy, autosave: true

    validates :path, presence: true, format: { with: /\A[a-z0-9_\-]{3,200}\z/ }, uniqueness: { scope: [:path, :closed_at, :hidden_at, :unpublished_at], case_sensitive: false }

    after_initialize :ensure_path_exists
    before_validation :temp
    before_validation :ensure_path_exists
    before_validation :add_procedure_path

    after_save :after_save

    # validates :procedure_paths, length: { minimum: 1 }
    # validates :procedure_paths, length: { minimum: 2 }, on: :publication

    scope :find_with_path, -> (path) { joins(:procedure_paths).where(procedure_paths: { path: }).limit(1) }

    def temp
      puts ""
      puts "(before_validation proc)"
      puts "*" * 100
      puts ""
      puts "id                         #{id}"
      puts "path                       #{path}"
      puts "Procedure.pluck(:path,:id) #{Procedure.pluck(:path, :id)}"
      puts "*" * 100
      puts ""
    end

    def ensure_path_exists
      if self.path.blank?
        self.path = SecureRandom.uuid
      end
    end

    def after_save
      puts ""
      puts "(after_save)"
      puts "path                                              #{path}"
      puts "id                                                #{id}"
      puts "Procedure.pluck(:path, :id)                       #{Procedure.pluck(:path, :id)}"
      puts "ProcedurePath.pluck(:path, :procedure_id)         #{ProcedurePath.pluck(:path, :procedure_id)}"
      puts ""
    end

    def add_procedure_path
      puts ""
      puts "(add_procedure_path)"
      puts "path                                              #{path}"
      puts "id                                                #{id}"
      puts "Procedure.pluck(:path, :id)                       #{Procedure.pluck(:path, :id)}"
      puts "ProcedurePath.pluck(:path, :procedure_id)         #{ProcedurePath.pluck(:path, :procedure_id)}"

      return if path.blank?

      # procedure_path = procedure_paths.find { _1.path == path } || procedure_paths.find_or_initialize_by(path: path)
      procedure_path = procedure_paths.find { _1.path == path } || ProcedurePath.find_or_initialize_by(path: path)

      puts "procedure_path.id                   #{procedure_path&.id}"
      puts "procedure_path.procedure_id         #{procedure_path&.procedure_id}"

      if procedure_path.procedure && procedure_path.procedure != self
        procedure_path.procedure.update!(path: SecureRandom.uuid)
      end

      procedure_paths << procedure_path

      procedure_path.updated_at = Time.zone.now

      puts "procedure_path.id                   #{procedure_path.id}"
      puts "procedure_path.procedure_id         #{procedure_path.procedure_id}"
      puts ""
      puts ""
    end

    def other_procedure_with_path(path)
      Procedure.publiees
        .where.not(id: self.id)
        .find_with_path(path).first
    end

    def claim_path!(administrateur, path)
      return if path.blank?

      procedure_path = ProcedurePath.find_by(path: path)

      raise "administrateur cannot claim a path of a procedure not owned" if !administrateur.owns?(procedure_path.procedure)

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
