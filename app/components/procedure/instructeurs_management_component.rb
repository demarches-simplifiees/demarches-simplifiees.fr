# frozen_string_literal: true

class Procedure::InstructeursManagementComponent < ApplicationComponent
  def initialize(procedure:, groupe_instructeur:, instructeurs:, available_instructeur_emails:, disabled_as_super_admin:)
    @procedure = procedure
    @groupe_instructeur = groupe_instructeur
    @instructeurs = instructeurs
    @available_instructeur_emails = available_instructeur_emails
    @disabled_as_super_admin = disabled_as_super_admin
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
