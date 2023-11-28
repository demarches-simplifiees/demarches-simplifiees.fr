class Champs::RepetitionChamp < Champ
  accepts_nested_attributes_for :champs
  delegate :libelle_for_export, to: :type_de_champ

  def rows
    dossier
      .champs_for_revision(type_de_champ)
      .group_by(&:row_id).values
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

  def blank?
    champs.empty?
  end

  def search_terms
    # The user cannot enter any information here so it doesn’t make much sense to search
  end

  def for_tag
    ([libelle] + rows.map do |champs|
      champs.map do |champ|
        "#{champ.libelle} : #{champ}"
      end.join("\n")
    end).join("\n\n")
  end

  def rows_for_export
    champs = dossier.champs_by_stable_id_with_row
    row_ids.each.with_index(1).map do |row_id, index|
      Champs::RepetitionChamp::Row.new(index: index, row_id:, dossier_id: dossier_id.to_s, champs:)
    end
  end

  class Row < Hashie::Dash
    property :index
    property :row_id
    property :dossier_id
    property :champs

    def read_attribute_for_serialization(attribute)
      self[attribute]
    end

    def spreadsheet_columns(types_de_champ)
      [
        ['Dossier ID', :dossier_id],
        ['Ligne', :index]
      ] + Dossier.champs_for_export(types_de_champ, champs, row_id)
    end
  end
end
