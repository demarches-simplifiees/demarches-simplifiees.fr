# frozen_string_literal: true

class ProcedurePath < ApplicationRecord
  belongs_to :procedure

  before_destroy :ensure_one_path, :ensure_is_customized

  before_validation :temp

  validates :path, presence: true, format: { with: /\A[a-z0-9_\-]{3,200}\z/ }, uniqueness: { case_sensitive: false }

  scope :by_updated_at, -> { order(updated_at: :desc) }

  def ensure_one_path
    return if procedure.procedure_paths.count > 1 || destroyed_by_association

    errors.add(:base, :at_least_one_path)
    throw(:abort)
  end

  def temp
    puts ""
    puts "*" * 100
    puts "(before_validation procedure_path)"
    puts "*" * 100

    puts "procedure_id                                #{procedure_id}"
    puts "path                                        #{path}"
    puts "ProcedurePath.pluck(:path, :procedure_id)   #{ProcedurePath.pluck(:path, :procedure_id)}"

    puts "*" * 100
    puts ""
  end

  def ensure_is_customized
    return if path_customized? || destroyed_by_association

    errors.add(:base, :cannot_delete_customized_path)
    throw(:abort)
  end

  def path_customized?
    !path.match?(/[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}/)
  end
end
