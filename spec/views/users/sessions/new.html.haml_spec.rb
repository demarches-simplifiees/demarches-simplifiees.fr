require 'spec_helper'

describe 'users/sessions/new.html.haml', type: :view do
  let(:dossier) { create :dossier }

  before(:each) do
    allow(view).to receive(:devise_mapping).and_return(Devise.mappings[:user])
    allow(view).to receive(:resource_name).and_return(:user)
  end

  before do
    assign(:user, User.new)
  end

  context 'when user_return_to session params contains a procedure_id' do
    before do
      assign(:dossier, dossier)
      render
    end

    it { expect(rendered).to have_selector('#form-login #logo_procedure') }
    it { expect(rendered).to have_selector('#form-login #titre-procedure') }
    it { expect(rendered).to have_content(dossier.procedure.libelle) }
    it { expect(rendered).to have_content(dossier.procedure.description) }
  end

  context 'when user_return_to session params not contains a procedure_id' do
    before do
      render
    end

    it { expect(rendered).to have_selector('#form-login #logo_tps') }
  end
end
