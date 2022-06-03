describe 'dossiers/dossier_vide.pdf.prawn', type: :view do
  let(:procedure) { create(:procedure, :with_all_champs, :with_drop_down_list) }
  let(:dossier) { create(:dossier, procedure: procedure) }

  before do
    assign(:procedure, procedure)
    assign(:dossier, dossier)
  end

  subject { render }

  it 'renders a PDF document with empty fields' do
    subject
    expect(rendered).to be_present
  end
end
