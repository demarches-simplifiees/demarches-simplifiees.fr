# frozen_string_literal: true

class Procedure::OneGroupeManagementComponent < ApplicationComponent
  include Logic

  def initialize(revision:, groupe_instructeur:)
    @revision = revision
    @groupe_instructeur = groupe_instructeur
    @procedure = revision.procedure
  end

  def csv_template
    template_path.open
  end

  def template_path
    Rails.public_path.join('csv/import-instructeurs-test.csv')
  end

  def template_url
    template_path.to_s
  end

  def template_detail
    "#{File.extname(csv_template.to_path).upcase.delete_prefix('.')} – #{number_to_human_size(csv_template.size)}"
  end
end
