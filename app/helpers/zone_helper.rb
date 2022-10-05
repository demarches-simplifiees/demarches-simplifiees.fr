module ZoneHelper
  def grouped_options_for_zone(date)
    date ||= Time.zone.now
    collectivite = Zone.find_by(acronym: "COLLECTIVITE")
    {
      "--" => [
        [I18n.t('i_dont_know', scope: 'utils'), nil],
        [collectivite.label, collectivite.id]
      ],
    I18n.t('ministeres', scope: 'zones') => (Zone.available_at(date) - [collectivite]).map { |m| [m.label_at(date), m.id] }
    }
  end
end
