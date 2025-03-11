# frozen_string_literal: true

class TypesDeChampEditor::ChampDropDownAdvancedComponent < TypesDeChampEditor::BaseChampComponent
  def render?
    @type_de_champ.drop_down_advanced?
  end

  def referentiel_max_size
    Administrateurs::TypesDeChampController::CSV_MAX_SIZE
  end

  def referentiel_max_lines
    Administrateurs::TypesDeChampController::CSV_MAX_LINES
  end

  def template_detail
    "#{file_extension} – #{file_size}"
  end

  def file_extension
    File.extname(template_file).upcase.delete_prefix(".")
  end

  def file_size
    file_size = Rails.public_path.join(template_file).size
    number_to_human_size(file_size)
  end

  def template_file
    'csv/modele-import-referentiel.csv'
  end
end
