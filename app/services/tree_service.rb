# frozen_string_literal: true

class TreeService
  def initialize(dossier)
    @dossier = dossier
  end

  def tree
    coordinates = @dossier.revision.revision_types_de_champ.filter(&:public?).filter(&:root?)
    tree_it(coordinates)
  end

  private

  def tree_it(coordinates, row_id: nil)
    return [] if coordinates.blank?

    head, *tail = coordinates

    if head.header_section?
      children, rest = tail.slice_before { same_level?(head, it) }.to_a
      tree_children = tree_it(children, row_id:)

      [to_champ(head, children: tree_children, row_id:)] + tree_it(rest, row_id:)

    elsif head.repetition?
      repetition = @dossier.project_champ(head.type_de_champ)
      rows = repetition.row_ids.map do |row_id|
        tree_children = tree_it(head.revision_types_de_champ, row_id:)
        Row.new(children: tree_children)
      end

      [to_champ(head, rows:)] + tree_it(tail)

    else
      [to_champ(head, row_id:)] + tree_it(tail, row_id:)
    end
  end

  def same_level?(header, el)
    el.header_section? &&
      header.type_de_champ.header_section_level_value == el.type_de_champ.header_section_level_value
  end

  def to_champ(coord, row_id: nil, children: nil, rows: nil)
    champ = @dossier.project_champ(coord.type_de_champ, row_id:)
    champ.children = children if children
    champ.new_rows = rows if rows
    champ
  end

  class Row
    attr_accessor :children, :parent
    def initialize(children: [])
      @children = children
      children.each { it.parent = self }
    end
  end
end
