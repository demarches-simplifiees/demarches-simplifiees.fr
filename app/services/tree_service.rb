# frozen_string_literal: true

class TreeService
  def initialize(dossier)
    @dossier = dossier
  end

  def tree(private: false)
    coordinates = @dossier.revision.revision_types_de_champ.filter(&:root?)
    tree_it(coordinates).tap { private ? it.filter(&:private?) : it.filter(&:public?) }
  end

  def submitted_tree(private: false)
    coordinates = @dossier.submitted_revision.revision_types_de_champ.filter(&:root?)
    tree_it(coordinates).tap { private ? it.filter(&:private?) : it.filter(&:public?) }
  end

  def discarded_tree
    submitted_tree.filter_map do |champ|
      current_champ = tree.find { it.stable_id == champ.stable_id }

      if current_champ.nil?
        champ
      elsif champ.repetition?
        champ.new_rows = champ.new_rows.map { |row| row - current_champ.new_rows.first }.compact
        champ.new_rows.any? ? champ : nil
      else
        nil
      end
    end
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
        tree_children = tree_it(repetition.revision_types_de_champ, row_id:)
        Row.new(children: tree_children)
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
    champ = @dossier.project_champ(coord.type_de_champ, row_id:)
    champ.children = children if children
    champ.new_rows = rows if rows
    champ.type_de_champ = coord.type_de_champ
    champ
  end

  def row_ids(coord)
    @dossier
      .champs
      .filter { it.stream == @dossier.stream }
      .filter(&:row?)
      .reject(&:discarded?)
      .filter { it.stable_id == coord.stable_id }
      .map(&:row_id).uniq.sort
  end

  class Row
    attr_accessor :children, :parent
    def initialize(children: [])
      @children = children
      children.each { it.parent = self }
    end

    def -(other)
      to_keep = children.map(&:stable_id) - other.children.map(&:stable_id)

      return nil if to_keep.empty?

      Row.new(children: children.filter { it.stable_id.in?(to_keep) })
    end
  end
end
