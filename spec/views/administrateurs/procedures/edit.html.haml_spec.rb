# frozen_string_literal: true

RSpec.describe 'administrateurs/procedures/edit', type: :view do
  let(:procedure) { create(:procedure, lien_site_web: 'http://some.website') }

  context 'when opendata is enabled' do
    it 'asks for opendata' do
      Rails.application.config.ds_opendata_enabled = true
      assign(:procedure, procedure)
      render

      expect(rendered).to have_content('Open data')
    end
  end

  context 'when opendata is disabled' do
    it 'asks for opendata' do
      Rails.application.config.ds_opendata_enabled = nil
      assign(:procedure, procedure)
      render

      expect(rendered).not_to have_content('Open data')
    end
  end
end
