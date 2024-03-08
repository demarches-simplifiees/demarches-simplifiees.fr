class MapFilter
  # https://api.rubyonrails.org/v7.1.1/classes/ActiveModel/Errors.html

  include ActiveModel::Conversion
  extend ActiveModel::Translation
  extend ActiveModel::Naming

  LEGEND = {
    nb_demarches: { 'nothing': -1, 'small': 20, 'medium': 50, 'large': 100, 'xlarge': 500 },
    nb_dossiers: { 'nothing': -1, 'small': 500, 'medium': 2000, 'large': 10000, 'xlarge': 50000 }
  }

  attr_accessor :stats
  attr_reader :errors

  def initialize(params)
    @params = params[:map_filter]&.permit(:kind, :year) || {}
    @errors = ActiveModel::Errors.new(self)
  end

  def persisted?
    false
  end

  def kind
    @params[:kind]&.to_sym || :nb_demarches
  end

  def year
    @params[:year].presence
  end

  def kind_buttons
    LEGEND.keys.map do
      { label: I18n.t("kind.#{_1}", scope:), value: _1 }
    end
  end

  def kind_legend_keys
    LEGEND[kind].keys
  end

  def css_class_for_departement(departement)
    if kind == :nb_demarches
      kind_legend_keys.reverse.find do
        nb_demarches_for_departement(departement) > LEGEND[kind][_1]
      end
    else
      kind_legend_keys.reverse.find do
        nb_dossiers_for_departement(departement) > LEGEND[kind][_1]
      end
    end
  end

  def nb_demarches_for_departement(departement)
    stats[departement.upcase] ? stats[departement.upcase][:nb_demarches] : 0
  end

  def nb_dossiers_for_departement(departement)
    stats[departement.upcase] ? stats[departement.upcase][:nb_dossiers] : 0
  end

  def legende_for(legende)
    limit = LEGEND[kind][legende]
    index = LEGEND[kind].keys.index(legende.to_sym)
    next_limit = LEGEND[kind].to_a[index + 1]
    if next_limit
      I18n.t(:legend, min_thresold: limit + 1, max_thresold: next_limit[1], scope:)
    else
      "> #{limit}"
    end
  end

  def detailed_title
    add_on = I18n.t(:specific_year_add_on, year:, scope:) if year
    I18n.t("detailed_title_for_#{kind}", add_on:, scope:)
  end

  private

  def scope
    'activemodel.attributes.map_filter'
  end
end
