require 'spec_helper'

RSpec.shared_examples 'not owner of dossier' do |controller, redirect|
  let(:dossier_2) { create(:dossier) }

  before do
    get controller, params: { dossier_id: dossier_2.id }
  end

  it 'redirect to home page' do
    expect(response).to redirect_to(redirect || '/')
  end

  it 'show a flash message error' do
    expect(flash[:alert]).to be_present
  end
end
