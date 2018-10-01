class ChampsService
  class << self
    def save_champs(champs, params)
      fill_champs(champs, params)

      champs.select(&:changed?).each(&:save)
    end

    def build_error_messages(champs)
      champs.select(&:mandatory_and_blank?)
        .map { |c| "Le champ #{c.libelle.truncate(200)} doit être rempli." }
    end

    def check_piece_justificative_files(champs)
      champs.select do |champ|
        champ.type_champ == TypeDeChamp.type_champs.fetch(:piece_justificative)
      end.map(&:piece_justificative_file_errors).flatten
    end

    private

    def fill_champs(champs, h)
      datetimes, not_datetimes = champs.partition { |c| c.type_champ == TypeDeChamp.type_champs.fetch(:datetime) }

      not_datetimes.each do |c|
        if c.type_champ == TypeDeChamp.type_champs.fetch(:piece_justificative) && h["champs"]["'#{c.id}'"].present?
          c.piece_justificative_file.attach(h["champs"]["'#{c.id}'"])
        else
          c.value = h[:champs]["'#{c.id}'"]
        end
      end

      datetimes.each { |c| c.value = parse_datetime(c.id, h) }
    end

    def parse_datetime(champ_id, h)
      "#{h[:champs]["'#{champ_id}'"]} #{extract_hour(champ_id, h)}:#{extract_minute(champ_id, h)}"
    end

    def extract_hour(champ_id, h)
      h[:time_hour]["'#{champ_id}'"]
    end

    def extract_minute(champ_id, h)
      h[:time_minute]["'#{champ_id}'"]
    end
  end
end
