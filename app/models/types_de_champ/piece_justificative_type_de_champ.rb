class TypesDeChamp::PieceJustificativeTypeDeChamp < TypesDeChamp::TypeDeChampBase
  extend ActionView::Helpers::TagHelper
  def estimated_fill_duration(revision)
    FILL_DURATION_LONG
  end

  # pf allows referencing PJs
  # def tags_for_template = [].freeze

  class << self
    def champ_value_for_tag(champ, path = nil)
      return nil unless champ.piece_justificative_file.attached?

      champ.piece_justificative_file.each_with_index.filter_map do |attachment, i|
        if attachment.virus_scanner.safe? || attachment.virus_scanner.pending?
          url = download_url(champ, i)
          display = attachment.filename
          if attachment.image?
            tag.img '', src: url, width: '100', id: attachment.id, display: display
          else
            tag.a(display, href: url, target: '_blank', rel: 'noopener', title: "Télécharger la pièce jointe")
          end
        end
      end.flat_map { |e| [e, ",", tag.br] }[0..-3].reduce(&:+)
    end

    def download_url(champ, index)
      if Champ.update_by_stable_id?
        Rails.application.routes.url_helpers.champs_piece_justificative_download_url(
          { dossier_id: champ.dossier_id, stable_id: champ.stable_id, h: champ.encoded_date(:created_at), i: index, row_id: champ.row_id }
        )
      else
        Rails.application.routes.url_helpers.champs_legacy_piece_justificative_download_url(
          { champ_id: champ.id, h: champ.encoded_date(:created_at), i: index }
        )
      end
    end

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
