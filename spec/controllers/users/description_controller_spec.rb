require 'spec_helper'

require 'controllers/users/description_controller_shared_example'

describe Users::DescriptionController, type: :controller, vcr: {cassette_name: 'controllers_users_description_controller'} do
  let(:owner_user) { create(:user) }
  let(:invite_by_user) { create :user, email: 'invite@plop.com' }
  let(:archived_at) { nil }
  let(:state) { 'en_construction' }

  let(:procedure) { create(:procedure, :with_two_type_de_piece_justificative, :with_type_de_champ, :with_datetime, cerfa_flag: true, published_at: Time.now, archived_at: archived_at) }
  let(:dossier) { create(:dossier, procedure: procedure, user: owner_user, state: state) }

  let(:dossier_id) { dossier.id }
  let(:bad_dossier_id) { Dossier.count + 10000 }

  let(:name_piece_justificative) { 'dossierPDF.pdf' }
  let(:name_piece_justificative_0) { 'piece_justificative_0.pdf' }
  let(:name_piece_justificative_1) { 'piece_justificative_1.pdf' }

  let(:cerfa_pdf) { Rack::Test::UploadedFile.new("./spec/support/files/#{name_piece_justificative}", 'application/pdf') }
  let(:piece_justificative_0) { Rack::Test::UploadedFile.new("./spec/support/files/#{name_piece_justificative_0}", 'application/pdf') }
  let(:piece_justificative_1) { Rack::Test::UploadedFile.new("./spec/support/files/#{name_piece_justificative_1}", 'application/pdf') }

  before do
    allow(ClamavService).to receive(:safe_file?).and_return(true)

    create :invite, dossier: dossier, user: invite_by_user, email: invite_by_user.email, type: 'InviteUser'

    sign_in user
  end

  context 'when sign in user is the owner' do
    let(:user) { owner_user }
    let(:recapitulatif_path) { users_dossier_recapitulatif_path }

    it_should_behave_like "description_controller_spec"
    it_should_behave_like "description_controller_spec_POST_piece_justificatives_for_owner"
  end

  context 'when sign in user is an invite by owner' do
    let(:user) { invite_by_user }
    let(:recapitulatif_path) { users_dossiers_invite_path(id: dossier_id) }

    it_should_behave_like "description_controller_spec"
  end
end
