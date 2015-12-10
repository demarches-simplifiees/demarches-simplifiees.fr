require 'spec_helper'

describe 'users/dossiers/new.html.haml', type: :view do
  let(:user) { create(:user) }
  let(:euro_flag) { false }
  let(:procedure) { create(:procedure, euro_flag: euro_flag) }
  let!(:dossier) { create(:dossier, procedure: procedure, user: user,).decorate }

  describe 'euro flag' do
    before do
      sign_in user

      assign(:dossier, dossier.decorate)
      render
    end

    subject { rendered }

    it { is_expected.to have_css('#users_siret_index') }

    context 'euro flag is not present' do
      it { is_expected.not_to have_css('#euro_flag.flag') }
    end

    context 'euro flag is present' do
      let(:euro_flag) { true }

      it { is_expected.to have_css('#euro_flag.flag') }
    end
  end
end