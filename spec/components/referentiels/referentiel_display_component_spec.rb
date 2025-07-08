# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Referentiels::ReferentielDisplayComponent, type: :component do
  let(:component) { described_class.new(referentiel: referentiel, type_de_champ: type_de_champ, procedure: procedure) }
  let(:procedure) { create(:procedure, types_de_champ_public: types_de_champ_public) }
  let(:types_de_champ_public) { [{ type: :referentiel, referentiel: referentiel, referentiel_mapping: }] }
  let(:type_de_champ) { procedure.draft_revision.types_de_champ_public.first }
  let(:referentiel) { create(:api_referentiel, :configured) }

  subject { render_inline(component) }

  describe 'render' do
    context 'when mapping is blank' do
      let(:referentiel_mapping) { {} }

      it { expect(subject.to_html).to be_empty }
    end

    context 'when mapping is present' do
      let(:referentiel_mapping) do
        {
          "$.jsonpath" => {
            "type" => "Chaine de caractère",
            "example_value" => "valeur",
            "libelle" => "Nom affiché",
            "display_usager" => "1",
            "display_instructeur" => '1'
          }
        }
      end

      it 'renders the table headers' do
        expect(subject).to have_selector('th', text: 'Propriété')
        expect(subject).to have_selector('th', text: 'Exemple de donnée')
        expect(subject).to have_selector('th', text: 'Type de donnée')
        expect(subject).to have_selector('th', text: 'Libellé de la donnée récupérée')
        expect(subject).to have_selector('th', text: 'Afficher à l’usager')
        expect(subject).to have_selector('th', text: 'Afficher à l’instructeur')
      end

      it 'renders a row with correct values' do
        expect(subject).to have_text('$.jsonpath')
        expect(subject).to have_text('valeur')
        expect(subject).to have_text('Chaine de caractère')
        expect(subject).to have_text('Nom affiché')
        expect(subject).to have_css("input[type='checkbox'][checked='checked']", count: 2) # Display to user
      end
    end
  end
end
