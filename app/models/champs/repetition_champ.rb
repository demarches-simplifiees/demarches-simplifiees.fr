# frozen_string_literal: true

class Champs::RepetitionChamp < Champ
  include ActionView::Helpers::TagHelper

  accepts_nested_attributes_for :champs

  def rows
    dossier
      .champs_for_revision(scope: type_de_champ)
      .group_by(&:row_id)
      .sort
      .map(&:second)
  end

  def row_ids
    rows.map { _1.first.row_id }
  end

  def add_row(revision)
    added_champs = []
    transaction do
      row_id = ULID.generate
      revision.children_of(type_de_champ).each do |type_de_champ|
        added_champs << type_de_champ.build_champ(row_id:)
      end
      self.champs << added_champs
    end
    added_champs
  end

  def remove_row(row_id)
    dossier.champs.where(row_id:).destroy_all
    dossier.champs.reload
  end

  def focusable_input_id
    rows.last&.first&.focusable_input_id
  end

  def blank?
    champs.empty?
  end

  def search_terms
    # The user cannot enter any information here so it doesn’t make much sense to search
  end

  def for_tag(path = :value)
    # replace DS text value with table
    # ([libelle] + rows.map do |champs|
    #   champs.map do |champ|
    #     "#{champ.libelle} : #{champ}"
    #   end.join("\n")
    # end).join("\n\n")

    return "" if rows.empty?

    header = tag.tr(rows[0].map { |c| tag.th(c.libelle) }.reduce(&:+))
    lines = rows.map do |champs|
      tag.tr(champs.map do |champ|
        for_tag = champ.for_tag
        tag.td(for_tag)
      end.reduce(&:+))
    end.reduce(&:+)
    tag.table(header + lines)
  end

  def rows_for_export
    row_ids.map.with_index(1) do |row_id, index|
      Champs::RepetitionChamp::Row.new(index:, row_id:, dossier:)
    end
  end

  class Row < Hashie::Dash
    property :index
    property :row_id
    property :dossier

    def dossier_id
      dossier.id.to_s
    end

    def read_attribute_for_serialization(attribute)
      self[attribute]
    end

    def spreadsheet_columns(types_de_champ)
      [
        ['Dossier ID', :dossier_id],
        ['Ligne', :index]
      ] + dossier.champs_for_export(types_de_champ, row_id)
    end
  end
end
