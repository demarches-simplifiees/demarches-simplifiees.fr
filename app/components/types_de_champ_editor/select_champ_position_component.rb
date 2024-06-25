class TypesDeChampEditor::SelectChampPositionComponent < ApplicationComponent
  def initialize(revision:, coordinate:)
    @revision = revision
    @coordinate = coordinate
  end

  def options
    [["Déplacer le champ après", @coordinate.stable_id]]
  end

  def describedby_id
    dom_id(@coordinate, :move_and_morph)
  end
end
