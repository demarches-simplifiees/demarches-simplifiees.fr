require 'spec_helper'

describe 'layouts/left_panels/_left_panel_users_dossierscontroller_index.html.haml', type: :view do

  shared_examples 'active_tab' do
    let(:user) { create :user }

    before do
      sign_in user

      assign :dossiers_list_facade, (DossiersListFacades.new user, param_list)

      render
    end

    subject { rendered }

    let(:active_class) { 'div.procedure_list_element.active '+active_klass }
    let(:param_list) { liste }

    it { is_expected.to have_selector(active_class) }
  end

  describe 'list brouillon' do
    let(:active_klass) { '.progress-bar-default' }
    let(:liste) { 'brouillon' }

    it_behaves_like 'active_tab'
  end

  describe 'list en construction' do
    let(:active_klass) { '.progress-bar-danger' }
    let(:liste) { 'a_traiter' }

    it_behaves_like 'active_tab'
  end

  describe 'list a depose' do
    let(:active_klass) { '.progress-bar-purple' }
    let(:liste) { 'valides' }

    it_behaves_like 'active_tab'
  end

  describe 'list en examen' do
    let(:active_klass) { '.progress-bar-default' }
    let(:liste) { 'en_instruction' }

    it_behaves_like 'active_tab'
  end

  describe 'list cloture' do
    let(:active_klass) { '.progress-bar-success' }
    let(:liste) { 'termine' }

    it_behaves_like 'active_tab'
  end

  describe 'list invite' do
    let(:active_klass) { '.progress-bar-warning' }
    let(:liste) { 'invite' }

    it_behaves_like 'active_tab'
  end
end