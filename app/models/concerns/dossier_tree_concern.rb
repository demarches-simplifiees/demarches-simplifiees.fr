# frozen_string_literal: true

module DossierTreeConcern
  extend ActiveSupport::Concern

  def link_parent_children!
    tree_it(revision.revision_types_de_champ.filter(&:root?))
  end

  def submitted_tree(private: false)
    coordinates = submitted_revision.revision_types_de_champ.filter(&:root?)
    tree_it(coordinates).tap { private ? it.filter(&:private?) : it.filter(&:public?) }
  end

  private

  def tree_it(coordinates, row_id: nil)
    return [] if coordinates.blank?

    head, *tail = coordinates

    case head
    in header if head.header_section?
      children, rest = tail.slice_before { same_level?(header, it) }.to_a
      tree_children = tree_it(children, row_id:)

      [to_champ(header, children: tree_children, row_id:)] + tree_it(rest, row_id:)

    in repetition if head.repetition?
      rows = row_ids(repetition).map do |row_id|
        repetition_champ = champs
          .filter { it.type == 'Champs::RepetitionChamp' }
          .find { it.row_id == row_id }
        tree_children = tree_it(repetition.revision_types_de_champ, row_id:)
        repetition_champ.children = tree_children
        repetition_champ
      end

      [to_champ(repetition, rows:)] + tree_it(tail)

    else
      [to_champ(head, row_id:)] + tree_it(tail, row_id:)
    end
  end

  def same_level?(header, el)
    el.header_section? &&
      header.type_de_champ.header_section_level_value == el.type_de_champ.header_section_level_value
  end

  def to_champ(coord, row_id: nil, children: nil, rows: nil)
    champ = project_champ(coord.type_de_champ, row_id:)
    champ.children = children if children
    champ.new_rows = rows if rows
    champ.type_de_champ = coord.type_de_champ
    champ
  end

  def row_ids(coord)
    champs
      .filter { it.stream == stream }
      .filter(&:row?)
      .reject(&:discarded?)
      .filter { it.stable_id == coord.stable_id }
      .map(&:row_id).uniq.sort
  end
end
