describe 'dossiers/dossier_vide.pdf.prawn', type: :view do
  let(:procedure) { create(:procedure, :with_all_champs, :with_drop_down_list) }
  let(:dossier) { create(:dossier, procedure: procedure) }

  before do
    assign(:procedure, procedure)
    assign(:dossier, dossier)
  end

  subject { render }

  describe "with local images" do
    before do
      stub_const("DOSSIER_PDF_EXPORT_LOGO_SRC", "app/assets/images/header/logo-ds-wide.png")
    end

    it 'renders a PDF document with empty fields' do
      subject
      expect(rendered).to be_present
    end
  end

  describe "with remote images" do
    before do
      stub_const("DOSSIER_PDF_EXPORT_LOGO_SRC", "https://example.org/images/logo.png")
    end

    it 'renders a PDF document with empty fields' do
      VCR.use_cassette("dossiers/dossier_vide") do
        subject
      end

      expect(rendered).to be_present
    end
  end
end
