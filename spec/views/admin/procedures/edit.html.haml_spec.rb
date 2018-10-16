require 'spec_helper'

describe 'admin/procedures/edit.html.haml', type: :view, vcr: { cassette_name: 'admin_procedure_edit' } do
  let(:logo) { Rack::Test::UploadedFile.new("./spec/fixtures/files/logo_test_procedure.png", 'image/png') }
  let(:procedure) { create(:procedure, logo: logo) }

  before do
    assign(:procedure, procedure)
    render
  end

  context 'when procedure logo is present' do
    it 'display on the page' do
      expect(rendered).to have_selector('#preview_procedure_logo')
    end
  end
end
