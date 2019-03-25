require 'spec_helper'

describe 'users/dossiers/identite.html.haml', type: :view do
  let(:procedure) { create(:simple_procedure, for_individual: true) }
  let(:dossier) { create(:dossier, :with_entreprise, :with_service, state: Dossier.states.fetch(:brouillon), procedure: procedure) }

  before do
    sign_in dossier.user
    assign(:dossier, dossier)
  end

  subject! { render }

  it 'has identity fields' do
    expect(rendered).to have_field('Prénom')
    expect(rendered).to have_field('Nom')
  end

  context 'when the demarche asks for the birthdate' do
    let(:procedure) { create(:simple_procedure, for_individual: true, ask_birthday: true) }

    it 'has a birthday field' do
      expect(rendered).to have_field('Date de naissance')
    end
  end
end
