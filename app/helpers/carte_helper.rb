# frozen_string_literal: true

module CarteHelper
  def svg_path(map_filter, departement, d)
    tag.path(
      class: "land departement departement#{departement} #{map_filter.css_class_for_departement(departement)}",
      'stroke-width': ".5",
      d: d,
      data: {
        departement: name_for_departement(departement),
        demarches: map_filter.nb_demarches_for_departement(departement),
        dossiers: map_filter.nb_dossiers_for_departement(departement),
        action: "mouseenter->map-info#showInfo mouseout->map-info#hideInfo",
      }
    )
  end

  def name_for_departement(departement)
    "#{departement.upcase} - #{APIGeoService.departement_name(departement.upcase)}"
  end
end
