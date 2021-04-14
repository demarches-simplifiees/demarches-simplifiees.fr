# == Schema Information
#
# Table name: champs
#
#  id                             :integer          not null, primary key
#  data                           :jsonb
#  fetch_external_data_exceptions :string           is an Array
#  private                        :boolean          default(FALSE), not null
#  row                            :integer
#  type                           :string
#  value                          :string
#  created_at                     :datetime
#  updated_at                     :datetime
#  dossier_id                     :integer
#  etablissement_id               :integer
#  external_id                    :string
#  parent_id                      :bigint
#  type_de_champ_id               :integer
#
class Champs::RepetitionChamp < Champ
  include ActionView::Helpers::TagHelper
  accepts_nested_attributes_for :champs, allow_destroy: true

  def rows
    champs.group_by(&:row).values
  end

  def add_row(row = 0)
    type_de_champ.types_de_champ.each do |type_de_champ|
      self.champs << type_de_champ.champ.build(row: row)
    end
  end

  def mandatory_and_blank?
    mandatory? && champs.empty?
  end

  def search_terms
    # The user cannot enter any information here so it doesn’t make much sense to search
  end

  def for_tag
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
        tag.td(champ.for_tag)
      end.reduce(&:+))
    end.reduce(&:+)
    tag.table(header + lines)
  end

  def rows_for_export
    rows.each.with_index(1).map do |champs, index|
      Champs::RepetitionChamp::Row.new(index: index, dossier_id: dossier_id.to_s, champs: champs)
    end
  end

  # We have to truncate the label here as spreadsheets have a (30 char) limit on length.
  def libelle_for_export
    str = "(#{stable_id}) #{libelle}"
    # /\*?[] are invalid Excel worksheet characters
    ActiveStorage::Filename.new(str.delete('[]*?')).sanitized
  end

  class Row < Hashie::Dash
    property :index
    property :dossier_id
    property :champs

    def read_attribute_for_serialization(attribute)
      self[attribute]
    end

    def spreadsheet_columns
      [
        ['Dossier ID', :dossier_id],
        ['Ligne', :index]
      ] + exported_champs
    end

    private

    def exported_champs
      champs.reject(&:exclude_from_export?).map do |champ|
        [champ.libelle, champ.for_export]
      end
    end
  end
end
