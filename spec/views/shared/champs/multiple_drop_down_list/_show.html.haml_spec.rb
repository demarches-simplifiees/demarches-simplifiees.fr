describe 'views/shared/champs/multiple_drop_down_list/_show.html.haml', type: :view do
  let(:champ) { build(:champ_multiple_drop_down_list, value: ['abc', '2, 3, 4']) }

  subject { render partial: 'shared/champs/multiple_drop_down_list/show', locals: { champ: champ } }

  it 'renders the view' do
    subject
    expect(rendered).to have_selector('li', count: champ.selected_options.size)
  end
end
