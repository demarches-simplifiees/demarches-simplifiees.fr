# frozen_string_literal: true

class Procedure::ImportComponent < ApplicationComponent
  def initialize(procedure:)
    @procedure = procedure
  end

  def scope
    @procedure.routing_enabled? ? 'groupes' : 'instructeurs'
  end

  def template_file
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
    CsvParsingConcern::CSV_MAX_SIZE
  end

  private

  def csv_template
    template_path.open
  end

  def template_path
    Rails.public_path.join(template_file.delete_prefix('/'))
  end
end
