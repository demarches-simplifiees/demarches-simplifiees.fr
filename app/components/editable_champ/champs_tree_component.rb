class EditableChamp::ChampsTreeComponent < ApplicationComponent
  include Champs::Treeable

  attr_reader :root

  def initialize(champs:, root_depth:)
    @root = to_tree(champs:, root_depth:, build_champs_subtree_component: method(:build_champs_subtree_component))
  end

  def build_champs_subtree_component(header_section:)
    EditableChamp::ChampsSubtreeComponent.new(header_section:)
  end
end
