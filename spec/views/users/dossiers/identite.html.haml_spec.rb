describe 'users/dossiers/identite', type: :view do
  let(:procedure) { create(:simple_procedure, :for_individual) }
  let(:dossier) { create(:dossier, :with_service, state: Dossier.states.fetch(:brouillon), procedure: procedure) }

  before do
    sign_in dossier.user
    assign(:dossier, dossier)
  end

  subject! { render }

  it 'has identity fields' do
    expect(rendered).to have_field(id: 'indiv_first_name')
    expect(rendered).to have_field(id: 'indiv_last_name')
  end

  context 'when the demarche asks for the birthdate' do
    let(:procedure) { create(:simple_procedure, for_individual: true, ask_birthday: true) }

    it 'has a birthday field' do
      expect(rendered).to have_field('Date de naissance')
    end
  end
end
