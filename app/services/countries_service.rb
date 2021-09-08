class CountriesService
  def self.get(locale)
    I18nData.countries(locale).merge(get_localized_additional_countries(locale))
  end

  def self.get_localized_additional_countries(locale)
    additional_countries[locale.to_s.upcase] || {}
  end

  def self.additional_countries
    {
      'FR' => { 'XK' => 'Kosovo' },
      'EN' => { 'XK' => 'Kosovo' }
    }
  end
end
