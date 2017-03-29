class ChampsService
  class << self
    def save_champs(champs, params, check_mandatory = true)
      fill_champs(champs, params)

      champs.select(&:changed?).each(&:save)

      check_mandatory ? build_error_messages(champs) : []
    end

    private

    def fill_champs(champs, h)
      datetimes, not_datetimes = champs.partition { |c| c.type_champ == 'datetime' }

      not_datetimes.each { |c| c.value = h[:champs]["'#{c.id}'"] }
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

    def build_error_messages(champs)
      champs.select(&:mandatory_and_blank?)
            .map { |c| build_champ_error_message(c) }
    end

    def build_champ_error_message(champ)
      { message: "Le champ #{champ.libelle} doit être rempli." }
    end
  end
end
