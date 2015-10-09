require 'spec_helper'

RSpec.shared_examples 'not owner of dossier' do |controller, redirect|
  let(:dossier_2) { create(:dossier, :with_user) }

  before do
    get controller, dossier_id: dossier_2.id
  end

  it 'redirect to home page' do
    redirect_page = '/'
    redirect_page = redirect unless redirect.nil?

    expect(response).to redirect_to(redirect_page)
  end

  it 'show a flash message error' do
    expect(flash[:alert]).to be_present
  end
end
