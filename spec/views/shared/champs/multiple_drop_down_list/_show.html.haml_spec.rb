describe 'views/shared/champs/multiple_drop_down_list/_show', type: :view do
  let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :multiple_drop_down_list }]) }
  let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
  let(:champ) { dossier.champs.first }

  before { champ.update(value: ['abc', '2, 3, 4']) }
  subject { render partial: 'shared/champs/multiple_drop_down_list/show', locals: { champ: } }

  it 'renders the view' do
    subject
    expect(rendered).to have_selector('li', count: champ.selected_options.size)
  end
end
