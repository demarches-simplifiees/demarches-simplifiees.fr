describe Administrateurs::GroupeInstructeursController, type: :controller do
  render_views

  let(:admin) { create(:administrateur) }
  let(:procedure) { create(:procedure, :published, :for_individual, administrateurs: [admin], routing_enabled: true) }
  let!(:gi_1_1) { procedure.defaut_groupe_instructeur }

  let(:procedure2) { create(:procedure, :published) }
  let!(:gi_2_2) { procedure2.groupe_instructeurs.create(label: 'groupe instructeur 2 2') }

  before { sign_in(admin.user) }

  describe '#index' do
    context 'of a procedure I own' do
      let!(:gi_1_2) { procedure.groupe_instructeurs.create(label: 'groupe instructeur 2') }

      before { get :index, params: { procedure_id: procedure.id } }

      context 'when a procedure has multiple groups' do
        it { expect(response).to have_http_status(:ok) }
        it { expect(response.body).to include(gi_1_1.label) }
        it { expect(response.body).to include(gi_1_2.label) }
        it { expect(response.body).not_to include(gi_2_2.label) }
      end
    end
  end

  describe '#show' do
    context 'of a group I belong to' do
      before { get :show, params: { procedure_id: procedure.id, id: gi_1_1.id } }

      it { expect(response).to have_http_status(:ok) }
    end

    context 'when the routage is not activated on the procedure' do
      let(:procedure) { create :procedure, administrateur: admin, instructeurs: [instructeur_assigned_1, instructeur_assigned_2] }
      let!(:instructeur_assigned_1) { create :instructeur, email: 'instructeur_1@ministere-a.gouv.fr', administrateurs: [admin] }
      let!(:instructeur_assigned_2) { create :instructeur, email: 'instructeur_2@ministere-b.gouv.fr', administrateurs: [admin] }
      let!(:instructeur_not_assigned_1) { create :instructeur, email: 'instructeur_3@ministere-a.gouv.fr', administrateurs: [admin] }
      let!(:instructeur_not_assigned_2) { create :instructeur, email: 'instructeur_4@ministere-b.gouv.fr', administrateurs: [admin] }
      subject! { get :show, params: { procedure_id: procedure.id, id: gi_1_1.id } }

      it { expect(response.status).to eq(200) }

      it 'sets the assigned and not assigned instructeurs' do
        expect(assigns(:instructeurs)).to match_array([instructeur_assigned_1, instructeur_assigned_2])
        expect(assigns(:available_instructeur_emails)).to match_array(['instructeur_3@ministere-a.gouv.fr', 'instructeur_4@ministere-b.gouv.fr'])
      end
    end
  end

  describe '#create' do
    before do
      post :create,
        params: {
          procedure_id: procedure.id,
          groupe_instructeur: { label: label }
        }
    end

    context 'with a valid name' do
      let(:label) { "nouveau_groupe" }

      it { expect(flash.notice).to be_present }
      it { expect(response).to redirect_to(admin_procedure_groupe_instructeur_path(procedure, procedure.groupe_instructeurs.last)) }
      it { expect(procedure.groupe_instructeurs.count).to eq(2) }
    end

    context 'with an invalid group name' do
      let(:label) { gi_1_1.label }

      it { expect(response).to render_template(:index) }
      it { expect(procedure.groupe_instructeurs.count).to eq(1) }
      it { expect(flash.alert).to be_present }
    end
  end

  describe '#destroy' do
    def delete_group(group)
      delete :destroy,
        params: {
          procedure_id: procedure.id,
          id: group.id
        }
    end

    context 'with only one group' do
      before { delete_group gi_1_1 }

      it { expect(flash.alert).to be_present }
      it { expect(response).to redirect_to(admin_procedure_groupe_instructeurs_path(procedure)) }
      it { expect(procedure.groupe_instructeurs.count).to eq(1) }
    end

    context 'with many groups' do
      let!(:gi_1_2) { procedure.groupe_instructeurs.create(label: 'groupe instructeur 2') }

      context 'of a group that can be deleted' do
        before { delete_group gi_1_2 }
        it { expect(flash.notice).to be_present }
        it { expect(procedure.groupe_instructeurs.count).to eq(1) }
        it { expect(response).to redirect_to(admin_procedure_groupe_instructeurs_path(procedure)) }
      end

      context 'of a group with dossiers, that cannot be deleted' do
        let!(:dossier12) { create(:dossier, procedure: procedure, state: Dossier.states.fetch(:en_construction), groupe_instructeur: gi_1_2) }
        before { delete_group gi_1_2 }

        it { expect(flash.alert).to be_present }
        it { expect(procedure.groupe_instructeurs.count).to eq(2) }
        it { expect(response).to redirect_to(admin_procedure_groupe_instructeurs_path(procedure)) }
      end
    end
  end

  describe '#reaffecter_dossiers' do
    let!(:gi_1_2) { procedure.groupe_instructeurs.create(label: 'groupe instructeur 2') }
    let!(:gi_1_3) { procedure.groupe_instructeurs.create(label: 'groupe instructeur 3') }

    before do
      get :reaffecter_dossiers,
        params: {
          procedure_id: procedure.id,
          id: gi_1_2.id
        }
    end
    def reaffecter_url(group)
      reaffecter_admin_procedure_groupe_instructeur_path(:id => gi_1_2,
                                                    :target_group => group)
    end

    it { expect(response).to have_http_status(:ok) }
    it { expect(response.body).to include(reaffecter_url(procedure.defaut_groupe_instructeur)) }
    it { expect(response.body).not_to include(reaffecter_url(gi_1_2)) }
    it { expect(response.body).to include(reaffecter_url(gi_1_3)) }
  end

  describe '#reaffecter' do
    let!(:gi_1_2) { procedure.groupe_instructeurs.create(label: 'groupe instructeur 2') }
    let!(:gi_1_3) { procedure.groupe_instructeurs.create(label: 'groupe instructeur 3') }
    let!(:dossier12) { create(:dossier, :en_construction, :with_individual, procedure: procedure, groupe_instructeur: gi_1_1) }
    let!(:instructeur) { create(:instructeur) }
    let!(:bulk_message) { BulkMessage.create(dossier_count: 2, dossier_state: "brouillon", body: "hello", sent_at: Time.zone.now, groupe_instructeurs: [gi_1_1, gi_1_3], instructeur: instructeur) }

    describe 'when the new group is a group of the procedure' do
      before do
        post :reaffecter,
          params: {
            procedure_id: procedure.id,
            id: gi_1_1.id,
            target_group: gi_1_2.id
          }
        dossier12.reload
        bulk_message.reload
      end

      it { expect(response).to redirect_to(admin_procedure_groupe_instructeurs_path(procedure)) }
      it { expect(gi_1_2.dossiers.last.id).to be(dossier12.id) }
      it { expect(dossier12.groupe_instructeur.id).to be(gi_1_2.id) }
      it { expect(bulk_message.groupe_instructeurs).to contain_exactly(gi_1_2, gi_1_3) }
    end

    describe 'when the target group is not a possible group' do
      subject {
        post :reaffecter,
          params:
            {
              procedure_id: procedure.id,
              id: gi_1_1.id,
              target_group: gi_2_2.id
            }
      }
      before do
        dossier12.reload
        bulk_message.reload
      end

      it { expect { subject }.to raise_error(ActiveRecord::RecordNotFound) }
      it { expect(bulk_message.groupe_instructeurs).to eq([gi_1_1, gi_1_3]) }
    end
  end

  describe '#update' do
    let(:new_name) { 'nouveau nom du groupe' }

    before do
      patch :update,
        params: {
          procedure_id: procedure.id,
          id: gi_1_1.id,
          groupe_instructeur: { label: new_name, closed: true }
        }
      gi_1_1.reload
    end

    it { expect(response).to redirect_to(admin_procedure_groupe_instructeur_path(procedure, gi_1_1)) }
    it { expect(gi_1_1.label).to eq(new_name) }
    it { expect(gi_1_1.closed).to eq(true) }
    it { expect(flash.notice).to be_present }

    context 'when the name is already taken' do
      let!(:gi_1_2) { procedure.groupe_instructeurs.create(label: 'groupe instructeur 2') }
      let(:new_name) { gi_1_2.label }

      it { expect(gi_1_1.label).not_to eq(new_name) }
      it { expect(flash.alert).to be_present }
    end
  end

  describe '#add_instructeur_procedure_non_routee' do
    let(:procedure) { create :procedure }
    let!(:groupe_instructeur) { create(:administrateurs_procedure, procedure: procedure, administrateur: admin, manager: manager) }
    let(:emails) { ['instructeur_3@ministere_a.gouv.fr', 'instructeur_4@ministere_b.gouv.fr'].to_json }
    subject { post :add_instructeur, params: { emails: emails, procedure_id: procedure.id, id: gi_1_1.id } }
    let(:manager) { false }
    context 'when all emails are valid' do
      let(:emails) { ['test@b.gouv.fr', 'test2@b.gouv.fr'].to_json }
      it { expect(response.status).to eq(200) }
      it { expect(subject.request.flash[:alert]).to be_nil }
      it { expect(subject.request.flash[:notice]).to be_present }
      it { expect(subject).to redirect_to admin_procedure_groupe_instructeurs_path(procedure) }
    end

    context 'when there is at least one bad email' do
      let(:emails) { ['badmail', 'instructeur2@gmail.com'].to_json }
      it { expect(response.status).to eq(200) }
      it { expect(subject.request.flash[:alert]).to be_present }
      it { expect(subject.request.flash[:notice]).to be_present }
      it { expect(subject).to redirect_to admin_procedure_groupe_instructeurs_path(procedure) }
    end

    context 'when the admin wants to assign an instructor who is already assigned on this procedure' do
      let(:emails) { ['instructeur_1@ministere_a.gouv.fr'].to_json }
      it { expect(subject.request.flash[:alert]).to be_present }
      it { expect(subject).to redirect_to admin_procedure_groupe_instructeurs_path(procedure) }
    end

    context 'when signed in admin comes from manager' do
      let(:manager) { true }
      it { is_expected.to have_http_status(:forbidden) }
    end
  end

  describe '#add_instructeur' do
    let!(:instructeur) { create(:instructeur) }
    let(:gi_1_2) { procedure.groupe_instructeurs.create(label: 'groupe instructeur 2') }
    let(:do_request) do
      post :add_instructeur,
        params: {
          procedure_id: procedure.id,
          id: gi_1_2.id,
          emails: new_instructeur_emails.to_json
        }
    end
    before do
      gi_1_2.instructeurs << instructeur

      allow(GroupeInstructeurMailer).to receive(:add_instructeurs)
        .and_return(double(deliver_later: true))
    end

    context 'of a news instructeurs' do
      let(:new_instructeur_emails) { ['new_i1@mail.com', 'new_i2@mail.com'] }
      before { do_request }
      it { expect(gi_1_2.instructeurs.pluck(:email)).to include(*new_instructeur_emails) }
      it { expect(flash.notice).to be_present }
      it { expect(response).to redirect_to(admin_procedure_groupe_instructeur_path(procedure, gi_1_2)) }
      it { expect(procedure.routee?).to be_truthy }
      it "calls GroupeInstructeurMailer with the right groupe and instructeurs" do
        expect(GroupeInstructeurMailer).to have_received(:add_instructeurs).with(
          gi_1_2,
          satisfy { |instructeurs| instructeurs.all? { |i| new_instructeur_emails.include?(i.email) } },
          admin.email
        )
      end
    end

    context 'of an instructeur already in the group' do
      let(:new_instructeur_emails) { [instructeur.email] }
      before { do_request }
      it { expect(response).to redirect_to(admin_procedure_groupe_instructeur_path(procedure, gi_1_2)) }
    end

    context 'of badly formed email' do
      let(:new_instructeur_emails) { ['badly_formed_email'] }
      before { do_request }
      it { expect(flash.alert).to be_present }
      it { expect(response).to redirect_to(admin_procedure_groupe_instructeur_path(procedure, gi_1_2)) }
    end

    context 'of an empty string' do
      let(:new_instructeur_emails) { [''] }
      before { do_request }
      it { expect(response).to redirect_to(admin_procedure_groupe_instructeur_path(procedure, gi_1_2)) }
    end

    context 'when connected as an administrateur from manager' do
      let(:new_instructeur_emails) { [instructeur.email] }
      before do
        admin.administrateurs_procedures.update_all(manager: true)
        do_request
      end

      it { expect(response).to have_http_status(:forbidden) }
    end
  end

  describe '#remove_instructeur' do
    let!(:instructeur) { create(:instructeur) }

    before { gi_1_1.instructeurs << admin.instructeur << instructeur }

    def remove_instructeur(instructeur)
      delete :remove_instructeur,
        params: {
          procedure_id: procedure.id,
          id: gi_1_1.id,
          instructeur: { id: instructeur.id }
        }
    end

    context 'when there are many instructeurs' do
      before { remove_instructeur(admin.instructeur) }

      it { expect(gi_1_1.instructeurs).to include(instructeur) }
      it { expect(gi_1_1.reload.instructeurs.count).to eq(1) }
      it { expect(response).to redirect_to(admin_procedure_groupe_instructeur_path(procedure, gi_1_1)) }
    end

    context 'when there is only one instructeur' do
      before do
        remove_instructeur(admin.instructeur)
        remove_instructeur(instructeur)
      end

      it { expect(gi_1_1.instructeurs).to include(instructeur) }
      it { expect(gi_1_1.instructeurs.count).to eq(1) }
      it { expect(flash.alert).to eq('Suppression impossible : il doit y avoir au moins un instructeur dans le groupe') }
      it { expect(response).to redirect_to(admin_procedure_groupe_instructeur_path(procedure, gi_1_1)) }
    end
  end

  describe '#remove_instructeur_procedure_non_routee' do
    let(:procedure) { create :procedure, administrateur: admin, instructeurs: [instructeur_assigned_1, instructeur_assigned_2] }
    let!(:instructeur_assigned_1) { create :instructeur, email: 'instructeur_1@ministere-a.gouv.fr', administrateurs: [admin] }
    let!(:instructeur_assigned_2) { create :instructeur, email: 'instructeur_2@ministere-b.gouv.fr', administrateurs: [admin] }
    let!(:instructeur_assigned_3) { create :instructeur, email: 'instructeur_3@ministere-a.gouv.fr', administrateurs: [admin] }
    subject! { get :show, params: { procedure_id: procedure.id, id: gi_1_1.id } }
    it 'sets the assigned instructeurs' do
      expect(assigns(:instructeurs)).to match_array([instructeur_assigned_1, instructeur_assigned_2])
    end

    context 'when the instructor is assigned to the procedure' do
      subject { delete :remove_instructeur, params: { instructeur: { id: instructeur_assigned_1.id }, procedure_id: procedure.id, id: gi_1_1.id } }
      it { expect(subject.request.flash[:notice]).to be_present }
      it { expect(subject.request.flash[:alert]).to be_nil }
      it { expect(response.status).to eq(302) }
      it { expect(subject).to redirect_to admin_procedure_groupe_instructeurs_path(procedure) }
    end

    context 'when the instructor is not assigned to the procedure' do
      subject { delete :remove_instructeur, params: { instructeur: { id: instructeur_assigned_3.id }, procedure_id: procedure.id, id: gi_1_1.id } }
      it { expect(subject.request.flash[:alert]).to be_present }
      it { expect(subject.request.flash[:notice]).to be_nil }
      it { expect(response.status).to eq(302) }
      it { expect(subject).to redirect_to admin_procedure_groupe_instructeurs_path(procedure) }
    end
  end

  describe '#add_groupe_instructeurs_via_csv_file' do
    subject do
      post :import, params: { procedure_id: procedure.id, group_csv_file: csv_file }
    end

    context 'when the csv file is less than 1 mo and content type text/csv' do
      let(:csv_file) { fixture_file_upload('spec/fixtures/files/groupe-instructeur.csv', 'text/csv') }

      before { subject }

      it { expect(response.status).to eq(302) }
      it { expect(procedure.groupe_instructeurs.last.label).to eq("Afrique") }
      it { expect(flash.alert).to be_present }
      it { expect(flash.alert).to eq("Import terminé. Cependant les emails suivants ne sont pas pris en compte: kara") }
    end

    context 'when the file content type is application/vnd.ms-excel' do
      let(:csv_file) { fixture_file_upload('spec/fixtures/files/groupe_avec_caracteres_speciaux.csv', "application/vnd.ms-excel") }

      before { subject }

      it { expect(flash.notice).to be_present }
      it { expect(flash.notice).to eq("La liste des instructeurs a été importée avec succès") }
    end

    context 'when the content of csv contains special characters' do
      let(:csv_file) { fixture_file_upload('spec/fixtures/files/groupe_avec_caracteres_speciaux.csv', 'text/csv') }

      before { subject }

      it { expect(procedure.groupe_instructeurs.pluck(:label)).to eq(["défaut", "Auvergne-Rhône-Alpes", "Vendée"]) }
      it { expect(flash.notice).to be_present }
      it { expect(flash.notice).to eq("La liste des instructeurs a été importée avec succès") }
    end

    context 'when the csv file length is more than 1 mo' do
      let(:csv_file) { fixture_file_upload('spec/fixtures/files/groupe-instructeur.csv', 'text/csv') }

      before do
        allow_any_instance_of(ActionDispatch::Http::UploadedFile).to receive(:size).and_return(3.megabytes)
        subject
      end

      it { expect(flash.alert).to be_present }
      it { expect(flash.alert).to eq("Importation impossible : le poids du fichier est supérieur à 1 Mo") }
    end

    context 'when the file content type is not accepted' do
      let(:csv_file) { fixture_file_upload('spec/fixtures/files/french-flag.gif', 'image/gif') }

      before { subject }

      it { expect(flash.alert).to be_present }
      it { expect(flash.alert).to eq("Importation impossible : veuillez importer un fichier CSV") }
    end

    context 'when the headers are wrong' do
      let(:csv_file) { fixture_file_upload('spec/fixtures/files/invalid-group-file.csv', 'text/csv') }

      before { subject }

      it { expect(flash.alert).to be_present }
      it { expect(flash.alert).to eq("Importation impossible, veuillez importer un csv <a href=\"/csv/#{I18n.locale}/import-groupe-test.csv\">suivant ce modèle</a>") }
    end
  end

  describe '#export_groupe_instructeurs' do
    let(:procedure) { create(:procedure, :published) }
    let(:gi_1_2) { procedure.groupe_instructeurs.create(label: 'groupe instructeur 1 2') }
    let(:instructeur_assigned_1) { create :instructeur, email: 'instructeur_1@ministere-a.gouv.fr', administrateurs: [admin] }
    let(:instructeur_assigned_2) { create :instructeur, email: 'instructeur_2@ministere-b.gouv.fr', administrateurs: [admin] }

    subject do
      get :export_groupe_instructeurs, params: { procedure_id: procedure.id, format: :csv }
    end

    before do
      procedure.administrateurs << admin
      gi_1_2.instructeurs << [instructeur_assigned_1, instructeur_assigned_2]
    end

    it 'generates a CSV file containing the instructeurs and groups' do
      expect(subject.status).to eq(200)
      expect(subject.stream.body.split("\n").size).to eq(3)
      expect(subject.stream.body).to include("groupe instructeur 1 2")
      expect(subject.stream.body).to include(instructeur_assigned_1.email)
      expect(subject.stream.body).to include(instructeur_assigned_2.email)
      expect(subject.header["Content-Disposition"]).to include("#{procedure.id}-groupe-instructeurs-#{Date.today}.csv")
    end
  end

  describe '#update_routing_criteria_name' do
    before do
      patch :update_routing_criteria_name,
        params: {
          procedure_id: procedure.id,
          procedure: { routing_criteria_name: 'new name !' }
        }
    end

    it { expect(procedure.reload.routing_criteria_name).to eq('new name !') }
  end
end
