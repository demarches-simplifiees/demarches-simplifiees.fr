require 'spec_helper'

describe 'users/dossiers/new.html.haml', type: :view do
  let(:user) { create(:user) }
  let(:euro_flag) { false }
  let(:cerfa_flag) { false }
  let(:logo) { '' }
  let(:procedure) { create(:procedure, euro_flag: euro_flag, cerfa_flag: cerfa_flag, logo: logo) }
  let!(:dossier) { create(:dossier, procedure: procedure, user: user).decorate }

  before do
    sign_in user

    assign(:dossier, dossier.decorate)
    render
  end

  subject { rendered }

  it { is_expected.to have_css('#users_siret_index') }

  describe 'euro flag' do
    context 'euro flag is not present' do
      it { is_expected.not_to have_css('#euro_flag.flag') }
    end

    context 'euro flag is present' do
      let(:euro_flag) { true }
      it { is_expected.to have_css('#euro_flag.flag') }
    end
  end

  describe 'logo procedure' do
    context 'procedure have no logo' do
      it 'TPS logo is present' do
        is_expected.to match(/src="\/assets\/logo-tps-.*\.png"/)
      end
    end

    context 'procedure have logo' do
      # let(:logo) { fixture_file_upload('spec/support/files/logo_test_procedure.png', 'image/png') }
      let(:logo) { File.new(File.join(::Rails.root.to_s, "/spec/support/files", "logo_test_procedure.png")) }

      it 'Procedure logo is present' do
        is_expected.to have_css("img[src='#{procedure.logo}']")
      end
    end
  end
end