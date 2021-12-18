module ZoneHelper
  def grouped_options_for_zone
    collectivite = Zone.find_by(acronym: "COLLECTIVITE")
    {
      "--" => [[I18n.t('i_dont_know', scope: 'utils'), nil], [collectivite.label, collectivite.id]],
      I18n.t('ministeres', scope: 'zones') => (Zone.order(:label) - [collectivite]).map { |m| [m.label, m.id] }
    }
  end
end
