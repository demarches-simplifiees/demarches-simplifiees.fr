require 'spec_helper'
require 'controllers/users/carte_controller_shared_example'

RSpec.describe Users::CarteController, type: :controller do
  let(:bad_adresse) { 'babouba' }

  let(:module_api_carto) { create(:module_api_carto, :with_api_carto) }
  let(:procedure) { create(:procedure, module_api_carto: module_api_carto) }
  let(:dossier) { create(:dossier, procedure: procedure) }

  let(:owner_user) { dossier.user }
  let(:invite_by_user) { create :user, email: 'invite@plop.com' }

  let(:dossier_with_no_carto) { create(:dossier) }
  let!(:etablissement) { create(:etablissement, dossier: dossier) }
  let(:bad_dossier_id) { Dossier.count + 1000 }
  let(:adresse) { etablissement.geo_adresse }

  before do
    create :invite, dossier: dossier, user: invite_by_user, email: invite_by_user.email

    sign_in user
  end

  context 'when sign in user is the owner' do
    let(:user) { owner_user }

    it_should_behave_like "carte_controller_spec"
  end

  context 'when sign in user is an invite by owner' do
    let(:user) { invite_by_user }

    it_should_behave_like "carte_controller_spec"
  end
end
