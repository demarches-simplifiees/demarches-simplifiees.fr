class TypesDeChamp::PieceJustificativeTypeDeChamp < TypesDeChamp::TypeDeChampBase
  def estimated_fill_duration(revision)
    FILL_DURATION_LONG
  end

  def tags_for_template = [].freeze

  class << self
    def champ_value_for_export(champ, path = :value)
      champ.piece_justificative_file.map { _1.filename.to_s }.join(', ')
    end

    def champ_value_for_api(champ, version = 2)
      return if version == 2

      # API v1 don't support multiple PJ
      attachment = champ.piece_justificative_file.first
      return if attachment.nil?

      if attachment.virus_scanner.safe? || attachment.virus_scanner.pending?
        attachment.url
      end
    end
  end
end
