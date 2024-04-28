# frozen_string_literal: true

describe 'users/dossiers/identite', type: :view do
  let(:dossier) { create(:dossier, :with_service, state: Dossier.states.fetch(:brouillon), procedure: procedure) }

  before do
    sign_in dossier.user
    assign(:dossier, dossier)
  end

  subject! { render }

  context 'when procedure has for_tiers_enabled' do
    let(:procedure) { create(:simple_procedure, :for_individual) }

    it 'has choice for you or a tiers' do
      expect(rendered).to have_content "Pour vous"
      expect(rendered).to have_content "Pour un bénéficiaire : membre de la famille, proche, mandant, professionnel en charge du suivi du dossier…"
    end

    it 'has identity fields' do
      within('.individual-infos') do
        expect(rendered).to have_field(id: 'Prenom')
        expect(rendered).to have_field(id: 'Nom')
      end
    end

    context 'when the demarche asks for the birthdate' do
      let(:procedure) { create(:simple_procedure, for_individual: true, ask_birthday: true) }

      it 'has a birthday field' do
        expect(rendered).to have_field('Date de naissance')
      end
    end
  end

  context 'when procedure has for_tiers_enabled' do
    let(:procedure) { create(:simple_procedure, :for_individual, for_tiers_enabled: false) }

    it 'has choice for you or a tiers' do
      expect(rendered).not_to have_content "Pour vous"
      expect(rendered).not_to have_content "Pour un bénéficiaire : membre de la famille, proche, mandant, professionnel en charge du suivi du dossier…"
    end

    it 'has identity fields' do
      within('.individual-infos') do
        expect(rendered).to have_field(id: 'Prenom')
        expect(rendered).to have_field(id: 'Nom')
      end
    end
  end
end
