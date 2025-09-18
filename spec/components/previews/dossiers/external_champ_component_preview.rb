# frozen_string_literal: true

class Dossiers::ExternalChampComponentPreview < ViewComponent::Preview
  def default
    data = [
      ['SIRET', '110 046 018 00013'],
      ['Dénomination', 'MINISTERE DE LA CULTURE'],
      ['Forme juridique', 'Ministère']
    ]

    details = [
      ['Libellé NAF', 'Administration publique générale'],
      ['Code NAF', '84.11Z'],
      ['Adresse', "182 rue Saint-Honoré\n75001 Paris"]
    ]

    source = 'Annuaire des Entreprises'

    details_footer = Dossiers::AnnuaireEntrepriseLinkComponent.new(siret: '11004601800013')

    component = Dossiers::ExternalChampComponent.new(data:, details:, source:, details_footer:)
    component.with_header { tag.p { 'Un header tres important' } }

    render_with_template(
      template: 'dossiers/external_champ_component_preview/default',
      locals: { component: }
    )
  end
end
