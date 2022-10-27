describe 'administrateurs/procedures/edit.html.haml' do
  let(:logo) { fixture_file_upload('spec/fixtures/files/logo_test_procedure.png', 'image/png') }
  let(:procedure) { create(:procedure, logo: logo, lien_site_web: 'http://some.website') }

  context 'when procedure logo is present' do
    it 'display on the page' do
      assign(:procedure, procedure)
      render

      expect(rendered).to have_selector('.procedure-logos')
    end
  end
end
