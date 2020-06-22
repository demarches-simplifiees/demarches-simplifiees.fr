describe 'new_administrateur/procedures/edit.html.haml' do
  let(:logo) { Rack::Test::UploadedFile.new("./spec/fixtures/files/logo_test_procedure.png", 'image/png') }
  let(:procedure) { create(:procedure, logo: logo, lien_site_web: 'http://some.website') }

  before do
    assign(:procedure, procedure)
    render
  end

  context 'when procedure logo is present' do
    it 'display on the page' do
      expect(rendered).to have_selector('.procedure-logos')
    end
  end
end
