# frozen_string_literal: true

class Procedure::ImportComponent < ApplicationComponent
  def initialize(procedure:)
    @procedure = procedure
  end

  def scope
    @procedure.routing_enabled? ? 'groupes' : 'instructeurs'
  end

  def template_url
    if @procedure.routing_enabled?
      '/csv/import-groupe-test.csv'
    else
      '/csv/import-instructeurs-test.csv'
    end
  end

  def template_detail
    "#{File.extname(csv_template.to_path).upcase.delete_prefix('.')} – #{number_to_human_size(csv_template.size)}"
  end

  def csv_max_size
    Administrateurs::GroupeInstructeursController::CSV_MAX_SIZE
  end

  private

  def csv_template
    template_path.open
  end

  def template_path
    if @procedure.routing_enabled?
      Rails.public_path.join('csv/import-groupe-test.csv')
    else
      Rails.public_path.join('csv/import-instructeurs-test.csv')
    end
  end
end
