class API::PaysController < ApplicationController
  before_action :authenticate_logged_user!

  def index
    countries = CountriesService.get('FR').zip(CountriesService.get(I18n.locale))
    countries = countries.map do |(code, value_fr), (localized_code, localized_value)|
      if code != localized_code
        raise "Countries lists mismatch. It means i18n_data gem has some internal inconsistencies."
      end

      {
        code: code,
        value: value_fr,
        label: localized_value
      }
    end

    render json: countries
  end
end
