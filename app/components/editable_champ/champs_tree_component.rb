class EditableChamp::ChampsTreeComponent < ApplicationComponent
  include TreeableConcern

  def initialize(champs:, root_depth:)
    @tree = to_tree(champs:, root_depth:)
  end
end
