describe Administrateurs::GroupeInstructeursController, type: :controller do
  render_views
  include Logic

  let(:admin) { administrateurs(:default_admin) }
  let(:procedure) { create(:procedure, :routee, :published, :for_individual, administrateurs: [admin]) }

  let!(:gi_1_1) { procedure.defaut_groupe_instructeur }
  let!(:gi_1_2) { procedure.defaut_groupe_instructeur.other_groupe_instructeurs.first }

  let(:procedure2) { create(:procedure, :routee, :published) }
  let!(:gi_2_2) { procedure2.defaut_groupe_instructeur.other_groupe_instructeurs.first }

  before { sign_in(admin.user) }

  describe '#index' do
    context 'of a procedure I own' do
      before { get :index, params: }

      context 'when a procedure has multiple groups' do
        let(:params) { { procedure_id: procedure.id } }

        it do
          expect(response).to have_http_status(:ok)
          expect(response.body).to include(gi_1_1.label)
          expect(response.body).to include(gi_1_2.label)
        end

        context 'when there is a search' do
          let(:params) { { procedure_id: procedure.id, q: 'deuxième' } }

          it do
            expect(assigns(:groupes_instructeurs)).to match_array([gi_1_2])
          end
        end
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

      it 'sets the assigned and not assigned instructeurs' do
        expect(response.status).to eq(200)
        expect(assigns(:instructeurs)).to match_array([instructeur_assigned_1, instructeur_assigned_2])
        expect(assigns(:available_instructeur_emails)).to match_array(['instructeur_3@ministere-a.gouv.fr', 'instructeur_4@ministere-b.gouv.fr'])
      end
    end

    context 'group with routing rule matching tdc' do
      let!(:drop_down_tdc) { create(:type_de_champ_drop_down_list, procedure: procedure, drop_down_options: options) }
      let(:options) { ['Premier choix', 'Deuxième choix', 'Troisième choix'] }

      before do
        gi_1_1.update(routing_rule: ds_eq(champ_value(drop_down_tdc.stable_id), constant('Deuxième choix')))
        get :show, params: { procedure_id: procedure.id, id: gi_1_1.id }
      end

      it do
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Deuxième choix')
        expect(response.body).not_to include('règle invalide')
      end
    end

    context 'group with routing rule not matching tdc' do
      let!(:drop_down_tdc) { create(:type_de_champ_drop_down_list, procedure: procedure, drop_down_options: options) }
      let(:options) { ['parmesan', 'brie', 'morbier'] }

      before do
        gi_1_1.update(routing_rule: ds_eq(champ_value(drop_down_tdc.stable_id), constant(gi_1_1.label)))
        get :show, params: { procedure_id: procedure.id, id: gi_1_1.id }
      end

      it do
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('règle invalide')
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

      it do
        expect(flash.notice).to be_present
        expect(response).to redirect_to(admin_procedure_groupe_instructeur_path(procedure, procedure.groupe_instructeurs.last))
        expect(procedure.groupe_instructeurs.count).to eq(3)
      end
    end

    context 'with an invalid group name' do
      let(:label) { gi_1_1.label }

      it do
        expect(response).to render_template(:index)
        expect(procedure.groupe_instructeurs.count).to eq(2)
        expect(flash.alert).to be_present
      end
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

    context 'default group' do
      before do
        delete_group gi_1_1
      end

      it 'verifies flash alerts and redirections' do
        expect(flash.alert).to be_present
        expect(flash.alert).to eq "Suppression impossible : le groupe « défaut » est le groupe par défaut."
        expect(response).to redirect_to(admin_procedure_groupe_instructeurs_path(procedure))
        expect(procedure.groupe_instructeurs.count).to eq(2)
      end
    end

    context 'with many groups' do
      context 'of a group that can be deleted' do
        before { delete_group gi_1_2 }

        it 'deletes the group and updates routing' do
          expect(flash.notice).to eq "le groupe « deuxième groupe » a été supprimé et le routage a été désactivé."
          expect(procedure.groupe_instructeurs.count).to eq(1)
          expect(procedure.reload.routing_enabled?).to eq(false)
          expect(response).to redirect_to(admin_procedure_groupe_instructeurs_path(procedure))
        end
      end

      context 'of a group with dossiers, that cannot be deleted' do
        let!(:dossier12) { create(:dossier, procedure: procedure, state: Dossier.states.fetch(:en_construction), groupe_instructeur: gi_1_2) }
        before { delete_group gi_1_2 }

        it 'attempts to delete a group with active dossiers and fails' do
          expect(flash.alert).to be_present
          expect(procedure.groupe_instructeurs.count).to eq(2)
          expect(response).to redirect_to(admin_procedure_groupe_instructeurs_path(procedure))
        end
      end
    end
  end

  describe '#reaffecter_dossiers' do
    let!(:gi_1_3) { create(:groupe_instructeur, label: 'groupe instructeur 3', procedure: procedure) }

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

    it 'checks response and body content for specific conditions' do
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(reaffecter_url(procedure.defaut_groupe_instructeur))
      expect(response.body).not_to include(reaffecter_url(gi_1_2))
      expect(response.body).to include(reaffecter_url(gi_1_3))
    end
  end

  describe '#reaffecter' do
    let!(:gi_1_3) { create(:groupe_instructeur, label: 'groupe instructeur 3', procedure: procedure) }
    let!(:dossier12) { create(:dossier, :en_construction, :with_individual, procedure: procedure, groupe_instructeur: gi_1_1) }
    let!(:instructeur) { create(:instructeur) }

    describe 'when the new group is a group of the procedure' do
      before do
        post :reaffecter,
          params: {
            procedure_id: procedure.id,
            id: gi_1_1.id,
            target_group: gi_1_2.id
          }
        dossier12.reload
      end

      it { expect(response).to redirect_to(admin_procedure_groupe_instructeurs_path(procedure)) }
      it { expect(gi_1_2.dossiers.last.id).to be(dossier12.id) }
      it { expect(dossier12.groupe_instructeur.id).to be(gi_1_2.id) }
      it { expect(dossier12.dossier_assignment.dossier_id).to be(dossier12.id) }
      it { expect(dossier12.dossier_assignment.groupe_instructeur_id).to be(gi_1_2.id) }
      it { expect(dossier12.dossier_assignment.assigned_by).to eq(admin.email) }
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
      end

      it { expect { subject }.to raise_error(ActiveRecord::RecordNotFound) }
    end
  end

  describe '#destroy_all_groups_but_defaut' do
    let!(:dossierA) { create(:dossier, :en_construction, :with_individual, procedure: procedure, groupe_instructeur: gi_1_2) }
    let!(:dossierB) { create(:dossier, :en_construction, :with_individual, procedure: procedure, groupe_instructeur: gi_1_2) }

    before do
      post :destroy_all_groups_but_defaut,
           params: {
             procedure_id: procedure.id
           }
      dossierA.reload
      dossierB.reload
    end

    it do
      expect(dossierA.groupe_instructeur.id).to be(procedure.defaut_groupe_instructeur.id)
      expect(dossierB.groupe_instructeur.id).to be(procedure.defaut_groupe_instructeur.id)
      expect(dossierA.dossier_assignment.dossier_id).to be(dossierA.id)
      expect(dossierB.dossier_assignment.dossier_id).to be(dossierB.id)
      expect(dossierA.dossier_assignment.groupe_instructeur_id).to be(procedure.defaut_groupe_instructeur.id)
      expect(dossierB.dossier_assignment.groupe_instructeur_id).to be(procedure.defaut_groupe_instructeur.id)
      expect(dossierA.dossier_assignment.assigned_by).to eq(admin.email)
      expect(dossierB.dossier_assignment.assigned_by).to eq(admin.email)
    end
  end
  describe '#update' do
    let(:new_name) { 'nouveau nom du groupe' }
    let!(:procedure_non_routee) { create(:procedure, :published, :for_individual, administrateurs: [admin]) }
    let!(:gi_1_1) { procedure_non_routee.defaut_groupe_instructeur }

    before do
      patch :update,
        params: {
          procedure_id: procedure_non_routee.id,
          id: gi_1_1.id,
          groupe_instructeur: { label: new_name }
        }
      gi_1_1.reload
    end

    it do
      expect(response).to redirect_to(admin_procedure_groupe_instructeur_path(procedure_non_routee, gi_1_1))
      expect(gi_1_1.label).to eq(new_name)
      expect(gi_1_1.closed).to eq(false)
      expect(flash.notice).to be_present
    end

    context 'when the name is already taken' do
      let!(:gi_1_2) { procedure_non_routee.groupe_instructeurs.create(label: 'deuxième groupe') }
      let(:new_name) { gi_1_2.label }

      it do
        expect(gi_1_1.label).not_to eq(new_name)
        expect(flash.alert).to eq(['Le libellé est déjà utilisé(e)'])
      end
    end
  end

  describe '#update_state' do
    let(:closed_value) { '0' }
    let!(:procedure_non_routee) { create(:procedure, :published, :for_individual, administrateurs: [admin]) }
    let!(:gi_1_1) { procedure_non_routee.defaut_groupe_instructeur }
    let!(:gi_1_2) { procedure_non_routee.groupe_instructeurs.create(label: 'deuxième groupe') }

    before do
      patch :update_state,
            params: {
              procedure_id: procedure_non_routee.id,
              groupe_instructeur_id: group.id,
              closed: closed_value
            }
      group.reload
    end

    context 'when we try do disable the default groupe instructeur' do
      let(:closed_value) { '1' }
      let(:group) { gi_1_1 }

      it do
        expect(subject).to redirect_to admin_procedure_groupe_instructeur_path(procedure_non_routee, gi_1_1)
        expect(gi_1_1.closed).to eq(false)
        expect(flash.alert).to eq('Il est impossible de désactiver le groupe d’instructeurs par défaut.')
      end
    end

    context 'when we try do disable the second groupe instructeur' do
      let(:closed_value) { '1' }
      let(:group) { gi_1_2 }

      it do
        expect(subject).to redirect_to admin_procedure_groupe_instructeur_path(procedure_non_routee, gi_1_2)
        expect(gi_1_2.closed).to eq(true)
        expect(flash.notice).to eq('Le groupe deuxième groupe est désactivé.')
      end
    end
  end

  describe '#add_instructeur_procedure_non_routee' do
    # faire la meme chose sur une procedure non routee
    let(:procedure_non_routee) { create(:procedure, administrateur: admin) }
    let(:emails) { ['instructeur_3@ministere_a.gouv.fr', 'instructeur_4@ministere_b.gouv.fr'] }
    let(:manager) { false }
    before {
      procedure_non_routee.administrateurs_procedures.where(administrateur: admin).update_all(manager:)
    }
    subject { post :add_instructeur, params: { emails: emails, procedure_id: procedure_non_routee.id, id: procedure_non_routee.defaut_groupe_instructeur.id } }
    context 'when all emails are valid' do
      let(:emails) { ['test@b.gouv.fr', 'test2@b.gouv.fr'] }
      it do
        expect(subject).to redirect_to admin_procedure_groupe_instructeurs_path(procedure_non_routee)
        expect(subject.request.flash[:alert]).to be_nil
        expect(subject.request.flash[:notice]).to be_present
      end
    end

    context 'when there is at least one bad email' do
      let(:emails) { ['badmail', 'instructeur2@gmail.com'] }
      it do
        expect(subject).to redirect_to admin_procedure_groupe_instructeurs_path(procedure_non_routee)
        expect(subject.request.flash[:alert]).to be_present
        expect(subject.request.flash[:notice]).to be_present
      end
    end

    context 'when the admin wants to assign an instructor who is already assigned on this procedure' do
      let(:instructeur) { create(:instructeur) }
      before { procedure_non_routee.groupe_instructeurs.first.add_instructeurs(emails: [instructeur.user.email]) }
      let(:emails) { [instructeur.email] }
      it { expect(subject).to redirect_to admin_procedure_groupe_instructeurs_path(procedure_non_routee) }
    end

    context 'when signed in admin comes from manager' do
      let(:manager) { true }
      it { is_expected.to have_http_status(:forbidden) }
    end
  end

  describe '#add_instructeur' do
    let!(:instructeur) { create(:instructeur) }
    let(:do_request) do
      post :add_instructeur,
        params: {
          procedure_id: procedure.id,
          id: gi_1_2.id,
          emails: new_instructeur_emails
        }
    end

    before { gi_1_2.instructeurs << instructeur }

    context 'of news instructeurs' do
      let!(:user_email_verified) { create(:user, :with_email_verified) }
      let!(:instructeur_email_verified) { create(:instructeur, user: user_email_verified) }
      let(:new_instructeur_emails) { ['new_i1@mail.com', 'new_i2@mail.com', instructeur_email_verified.email] }

      before do
        allow(GroupeInstructeurMailer).to receive(:notify_added_instructeurs)
          .and_return(double(deliver_later: true))

        allow(InstructeurMailer).to receive(:confirm_and_notify_added_instructeur)
          .and_return(double(deliver_later: true))
        do_request
      end
      it 'validates changes and responses' do
        expect(gi_1_2.instructeurs.pluck(:email)).to include(*new_instructeur_emails)
        expect(flash.notice).to be_present
        expect(response).to redirect_to(admin_procedure_groupe_instructeur_path(procedure, gi_1_2))
        expect(procedure.routing_enabled?).to be_truthy
        expect(GroupeInstructeurMailer).to have_received(:notify_added_instructeurs).with(
          gi_1_2,
          [instructeur_email_verified],
          admin.email
        )
      end

      it "calls InstructeurMailer with the right params" do
        expect(InstructeurMailer).to have_received(:confirm_and_notify_added_instructeur).with(
          User.find_by(email: 'new_i1@mail.com').instructeur,
          gi_1_2,
          admin.email
        )

        expect(InstructeurMailer).to have_received(:confirm_and_notify_added_instructeur).with(
          User.find_by(email: 'new_i2@mail.com').instructeur,
          gi_1_2,
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
      it do
      expect(flash.alert).to be_present
      expect(response).to redirect_to(admin_procedure_groupe_instructeur_path(procedure, gi_1_2))
    end
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

    before do
      gi_1_1.instructeurs << admin.instructeur << instructeur
      procedure.update(routing_enabled: true)
    end

    def remove_instructeur(instructeur)
      delete :remove_instructeur,
        params: {
          procedure_id: procedure.id,
          id: gi_1_1.id,
          instructeur: { id: instructeur.id }
        }
    end

    context 'when there are many instructeurs' do
      before do
        allow(GroupeInstructeurMailer).to receive(:notify_removed_instructeur)
          .and_return(double(deliver_later: true))
        remove_instructeur(admin.instructeur)
      end

      it 'verifies instructeurs and sends notifications' do
        expect(gi_1_1.instructeurs).to include(instructeur)
        expect(gi_1_1.reload.instructeurs.count).to eq(1)
        expect(response).to redirect_to(admin_procedure_groupe_instructeur_path(procedure, gi_1_1))
        expect(GroupeInstructeurMailer).to have_received(:notify_removed_instructeur).with(
          gi_1_1,
          admin.instructeur,
          admin.email
        )
      end
    end

    context 'when there is only one instructeur' do
      before do
        remove_instructeur(admin.instructeur)
        remove_instructeur(instructeur)
      end

      it 'validates remaining instructeur and checks alert message' do
        expect(gi_1_1.instructeurs).to include(instructeur)
        expect(gi_1_1.instructeurs.count).to eq(1)
        expect(flash.alert).to eq('Suppression impossible : il doit y avoir au moins un instructeur dans le groupe')
        expect(response).to redirect_to(admin_procedure_groupe_instructeur_path(procedure, gi_1_1))
      end
    end
  end

  describe '#remove_instructeur_procedure_non_routee' do
    let(:procedure_non_routee) { create :procedure, administrateur: admin, instructeurs: [instructeur_assigned_1, instructeur_assigned_2] }
    let!(:instructeur_assigned_1) { create :instructeur, email: 'instructeur_1@ministere-a.gouv.fr', administrateurs: [admin] }
    let!(:instructeur_assigned_2) { create :instructeur, email: 'instructeur_2@ministere-b.gouv.fr', administrateurs: [admin] }
    let!(:instructeur_assigned_3) { create :instructeur, email: 'instructeur_3@ministere-a.gouv.fr', administrateurs: [admin] }
    subject! { get :show, params: { procedure_id: procedure_non_routee.id, id: procedure_non_routee.defaut_groupe_instructeur.id } }
    it 'sets the assigned instructeurs' do
      expect(assigns(:instructeurs)).to match_array([instructeur_assigned_1, instructeur_assigned_2])
    end

    context 'when the instructor is assigned to the procedure' do
      subject do
        delete :remove_instructeur, params: {
          instructeur: { id: instructeur_assigned_1.id },
          procedure_id: procedure_non_routee.id,
          id: procedure_non_routee.defaut_groupe_instructeur.id
        }
      end

      it 'processes the removal of an assigned instructeur and checks response' do
        expect(subject.request.flash[:notice]).to be_present
        expect(subject.request.flash[:alert]).to be_nil
        expect(response.status).to eq(302)
        expect(subject).to redirect_to admin_procedure_groupe_instructeurs_path(procedure_non_routee)
      end
    end

    context 'when the instructor is not assigned to the procedure' do
      subject do
        delete :remove_instructeur, params: {
          instructeur: { id: instructeur_assigned_3.id },
          procedure_id: procedure_non_routee.id,
          id: procedure_non_routee.defaut_groupe_instructeur.id
        }
      end

      it 'attempts to remove an unassigned instructeur and validates alerts' do
        expect(subject.request.flash[:alert]).to be_present
        expect(subject.request.flash[:notice]).to be_nil
        expect(response.status).to eq(302)
        expect(subject).to redirect_to admin_procedure_groupe_instructeurs_path(procedure_non_routee)
      end
    end
  end

  describe '#import' do
    subject do
      post :import, params: { procedure_id: procedure.id, csv_file: csv_file }
    end

    context 'routed procedures' do
      context 'when the csv file is less than 1 mo and content type text/csv' do
        let(:csv_file) { fixture_file_upload('spec/fixtures/files/groupe-instructeur.csv', 'text/csv') }

        before { subject }

        it 'checks multiple response aspects after CSV upload' do
          expect(response.status).to eq(302)
          expect(procedure.groupe_instructeurs.first.label).to eq("Afrique")
          expect(flash.alert).to be_present
          expect(flash.alert).to eq("Import terminé. Cependant les emails suivants ne sont pas pris en compte: kara")
        end
      end

      context 'when the csv file has only one column' do
        let(:csv_file) { fixture_file_upload('spec/fixtures/files/valid-instructeurs-file.csv', 'text/csv') }

        before { subject }

        it 'handles one column CSV file gracefully' do
          expect { subject }.not_to raise_error
          expect(response.status).to eq(302)
          expect(flash.alert).to be_present
          expect(flash.alert).to eq("Importation impossible, veuillez importer un csv suivant <a href=\"/csv/import-instructeurs-test.csv\">ce modèle</a> pour une procédure sans routage ou <a href=\"/csv/fr/import-groupe-test.csv\">celui-ci</a> pour une procédure routée")
        end
      end

      context 'when the file content type is application/vnd.ms-excel' do
        let(:csv_file) { fixture_file_upload('spec/fixtures/files/groupe_avec_caracteres_speciaux.csv', "application/vnd.ms-excel") }

        before { subject }

        it 'imports excel file with success notice' do
          expect(flash.notice).to be_present
          expect(flash.notice).to eq("La liste des instructeurs a été importée avec succès")
        end
      end

      context 'when the content of csv contains special characters' do
        let(:csv_file) { fixture_file_upload('spec/fixtures/files/groupe_avec_caracteres_speciaux.csv', 'text/csv') }

        before do
          allow(GroupeInstructeurMailer).to receive(:notify_added_instructeurs)
            .and_return(double(deliver_later: true))
          subject
        end

        it 'processes CSV with special characters and sends notifications' do
          expect(procedure.groupe_instructeurs.pluck(:label)).to match_array(["Auvergne-Rhône-Alpes", "Vendée", "défaut", "deuxième groupe"])
          expect(flash.notice).to be_present
          expect(flash.notice).to eq("La liste des instructeurs a été importée avec succès")
          expect(GroupeInstructeurMailer).to have_received(:notify_added_instructeurs).twice
        end
      end

      context 'when the csv file length is more than 1 mo' do
        let(:csv_file) { fixture_file_upload('spec/fixtures/files/groupe-instructeur.csv', 'text/csv') }

        before do
          allow_any_instance_of(ActionDispatch::Http::UploadedFile).to receive(:size).and_return(3.megabytes)
          subject
        end

        it 'verifies the file size limitation' do
          expect(flash.alert).to be_present
          expect(flash.alert).to eq("Importation impossible : le poids du fichier est supérieur à 1 Mo")
        end
      end

      context 'when the file content type is not accepted' do
        let(:csv_file) { fixture_file_upload('spec/fixtures/files/french-flag.gif', 'image/gif') }

        before { subject }

        it 'checks file format acceptance' do
          expect(flash.alert).to be_present
          expect(flash.alert).to eq("Importation impossible : veuillez importer un fichier CSV")
        end
      end

      context 'when the headers are wrong' do
        let(:csv_file) { fixture_file_upload('spec/fixtures/files/invalid-group-file.csv', 'text/csv') }

        before { subject }

        it 'validates the header format of CSV' do
          expect(flash.alert).to be_present
          expect(flash.alert).to eq("Importation impossible, veuillez importer un csv suivant <a href=\"/csv/import-instructeurs-test.csv\">ce modèle</a> pour une procédure sans routage ou <a href=\"/csv/fr/import-groupe-test.csv\">celui-ci</a> pour une procédure routée")
        end
      end

      context 'when procedure is closed' do
        let(:procedure) { create(:procedure, :closed, administrateurs: [admin]) }
        let(:csv_file) { fixture_file_upload('spec/fixtures/files/groupe-instructeur.csv', 'text/csv') }

        before { subject }

        it 'handles imports with closed procedures' do
          expect(procedure.groupe_instructeurs.first.label).to eq("Afrique")
          expect(flash.alert).to eq("Import terminé. Cependant les emails suivants ne sont pas pris en compte: kara")
        end
      end

      context 'when emails are invalid' do
        let(:procedure) { create(:procedure, :closed, administrateurs: [admin]) }
        let(:csv_file) { fixture_file_upload('spec/fixtures/files/groupe-instructeur-emails-invalides.csv', 'text/csv') }

        before do
          allow(GroupeInstructeurMailer).to receive(:notify_added_instructeurs)
            .and_return(double(deliver_later: true))
          subject
        end

        it 'manages CSV with invalid emails and checks for mailer action' do
          expect(flash.alert).to include("Import terminé. Cependant les emails suivants ne sont pas pris en compte:")
          expect(GroupeInstructeurMailer).not_to have_received(:notify_added_instructeurs)
        end
      end
    end

    context 'unrouted procedures' do
      let(:procedure_non_routee) { create(:procedure, :published, :for_individual, administrateurs: [admin]) }

      subject do
        post :import, params: { procedure_id: procedure_non_routee.id, csv_file: csv_file }
      end

      context 'when the csv file is less than 1 mo and content type text/csv' do
        let(:csv_file) { fixture_file_upload('spec/fixtures/files/instructeurs-file.csv', 'text/csv') }

        before do
          allow(GroupeInstructeurMailer).to receive(:notify_added_instructeurs)
            .and_return(double(deliver_later: true))
          subject
        end

        it 'verifies response status, updates instructors, and sends alerts with email issues' do
          expect(response.status).to eq(302)
          expect(procedure_non_routee.instructeurs.pluck(:email)).to match_array(["kara@beta-gouv.fr", "philippe@mail.com", "lisa@gouv.fr"])
          expect(flash.alert).to be_present
          expect(flash.alert).to eq("Import terminé. Cependant les emails suivants ne sont pas pris en compte: eric")
          expect(GroupeInstructeurMailer).to have_received(:notify_added_instructeurs).with(
            procedure_non_routee.defaut_groupe_instructeur,
            any_args,
            admin.email
          )
        end
      end

      context 'when the csv file has more than one column' do
        let(:csv_file) { fixture_file_upload('spec/fixtures/files/groupe-instructeur.csv', 'text/csv') }

        before { subject }

        it 'confirms multiple column CSV import, response, and routing changes' do
          expect(response.status).to eq(302)
          expect(flash.alert).to be_present
          expect(flash.alert).to eq("Import terminé. Cependant les emails suivants ne sont pas pris en compte: kara")
          expect(procedure_non_routee.reload.routing_enabled?).to be_truthy
        end
      end

      context 'when the file content type is application/vnd.ms-excel' do
        let(:csv_file) { fixture_file_upload('spec/fixtures/files/valid-instructeurs-file.csv', "application/vnd.ms-excel") }

        before { subject }

        it 'handles excel file upload and verifies imported instructor emails' do
          expect(procedure_non_routee.instructeurs.pluck(:email)).to match_array(["kara@beta-gouv.fr", "philippe@mail.com", "lisa@gouv.fr"])
          expect(flash.notice).to be_present
          expect(flash.notice).to eq("La liste des instructeurs a été importée avec succès")
        end
      end

      context 'when the csv file length is more than 1 mo' do
        let(:csv_file) { fixture_file_upload('spec/fixtures/files/groupe-instructeur.csv', 'text/csv') }

        before do
          allow_any_instance_of(ActionDispatch::Http::UploadedFile).to receive(:size).and_return(3.megabytes)
          subject
        end

        it 'checks for file size limit and displays appropriate flash alert' do
          expect(flash.alert).to be_present
          expect(flash.alert).to eq("Importation impossible : le poids du fichier est supérieur à 1 Mo")
        end
      end

      context 'when the file content type is not accepted' do
        let(:csv_file) { fixture_file_upload('spec/fixtures/files/french-flag.gif', 'image/gif') }

        before { subject }

        it 'validates file format and displays a flash alert' do
          expect(flash.alert).to be_present
          expect(flash.alert).to eq("Importation impossible : veuillez importer un fichier CSV")
        end
      end

      context 'when emails are invalid' do
        let(:csv_file) { fixture_file_upload('spec/fixtures/files/instructeurs-emails-invalides.csv', 'text/csv') }

        before do
          allow(GroupeInstructeurMailer).to receive(:notify_added_instructeurs)
            .and_return(double(deliver_later: true))
          subject
        end

        it 'verifies email validity in CSV imports and checks for mailer not being called' do
          expect(flash.alert).to include("Import terminé. Cependant les emails suivants ne sont pas pris en compte:")
          expect(GroupeInstructeurMailer).not_to have_received(:notify_added_instructeurs)
        end
      end
    end
  end

  describe '#export_groupe_instructeurs' do
    let(:instructeur_assigned_1) { create :instructeur, email: 'instructeur_1@ministere-a.gouv.fr', administrateurs: [admin] }
    let(:instructeur_assigned_2) { create :instructeur, email: 'instructeur_2@ministere-b.gouv.fr', administrateurs: [admin] }

    subject do
      get :export_groupe_instructeurs, params: { procedure_id: procedure.id, format: :csv }
    end

    before do
      gi_1_2.instructeurs << [instructeur_assigned_1, instructeur_assigned_2]
    end

    it 'generates a CSV file containing the instructeurs and groups' do
      expect(subject.status).to eq(200)
      expect(subject.stream.body.split("\n").size).to eq(3)
      expect(subject.stream.body).to include("deuxième groupe")
      expect(subject.stream.body).to include(instructeur_assigned_1.email)
      expect(subject.stream.body).to include(instructeur_assigned_2.email)
      expect(subject.header["Content-Disposition"]).to include("#{procedure.id}-groupe-instructeurs-#{Date.today}.csv")
    end
  end

  describe '#create_simple_routing' do
    context 'with a drop_down_list type de champ' do
      let!(:procedure3) do
        create(:procedure,
               types_de_champ_public: [
                 { type: :drop_down_list, libelle: 'Votre ville', options: ['Paris', 'Lyon', 'Marseille'] },
                 { type: :text, libelle: 'Un champ texte' }
               ],
               administrateurs: [admin])
      end

      let!(:drop_down_tdc) { procedure3.draft_revision.types_de_champ.first }

      before { post :create_simple_routing, params: { procedure_id: procedure3.id, create_simple_routing: { stable_id: drop_down_tdc.stable_id } } }

      it do
        expect(response).to redirect_to(admin_procedure_groupe_instructeurs_path(procedure3))
        expect(flash.notice).to eq 'Les groupes instructeurs ont été ajoutés'
        expect(procedure3.groupe_instructeurs.pluck(:label)).to match_array(['Paris', 'Lyon', 'Marseille'])
        expect(procedure3.reload.defaut_groupe_instructeur.routing_rule).to eq(ds_eq(champ_value(drop_down_tdc.stable_id), constant('Lyon')))
        expect(procedure3.routing_enabled).to be_truthy
      end
    end

    context 'with a departements type de champ' do
      let!(:procedure3) do
        create(:procedure,
               types_de_champ_public: [{ type: :departements }],
               administrateurs: [admin])
      end

      let!(:departements_tdc) { procedure3.draft_revision.types_de_champ.first }

      before { post :create_simple_routing, params: { procedure_id: procedure3.id, create_simple_routing: { stable_id: departements_tdc.stable_id } } }

      it do
        expect(response).to redirect_to(admin_procedure_groupe_instructeurs_path(procedure3))
        expect(flash.notice).to eq 'Les groupes instructeurs ont été ajoutés'
        expect(procedure3.groupe_instructeurs.pluck(:label)).to include("01 – Ain")
        expect(procedure3.reload.defaut_groupe_instructeur.routing_rule).to eq(ds_eq(champ_value(departements_tdc.stable_id), constant('01')))
        expect(procedure3.routing_enabled).to be_truthy
      end
    end

    context 'with a regions type de champ' do
      let!(:procedure3) do
        create(:procedure,
               types_de_champ_public: [{ type: :regions }],
               administrateurs: [admin])
      end

      let!(:regions_tdc) { procedure3.draft_revision.types_de_champ.first }

      before { post :create_simple_routing, params: { procedure_id: procedure3.id, create_simple_routing: { stable_id: regions_tdc.stable_id } } }

      it do
        expect(response).to redirect_to(admin_procedure_groupe_instructeurs_path(procedure3))
        expect(flash.notice).to eq 'Les groupes instructeurs ont été ajoutés'
        expect(procedure3.groupe_instructeurs.pluck(:label)).to include("01 – Guadeloupe")
        expect(procedure3.reload.defaut_groupe_instructeur.routing_rule).to eq(ds_eq(champ_value(regions_tdc.stable_id), constant('01')))
        expect(procedure3.routing_enabled).to be_truthy
      end
    end

    context 'with a communes type de champ' do
      let!(:procedure3) do
        create(:procedure,
               types_de_champ_public: [{ type: :communes }],
               administrateurs: [admin])
      end

      let!(:communes_tdc) { procedure3.draft_revision.types_de_champ.first }

      before { post :create_simple_routing, params: { procedure_id: procedure3.id, create_simple_routing: { stable_id: communes_tdc.stable_id } } }

      it do
        expect(response).to redirect_to(admin_procedure_groupe_instructeurs_path(procedure3))
        expect(flash.notice).to eq 'Les groupes instructeurs ont été ajoutés'
        expect(procedure3.groupe_instructeurs.pluck(:label)).to include("01 – Ain")
        expect(procedure3.reload.defaut_groupe_instructeur.routing_rule).to eq(ds_in_departement(champ_value(communes_tdc.stable_id), constant('01')))
        expect(procedure3.routing_enabled).to be_truthy
      end
    end

    context 'with an epci type de champ' do
      let!(:procedure3) do
        create(:procedure,
               types_de_champ_public: [{ type: :epci }],
               administrateurs: [admin])
      end

      let!(:epci_tdc) { procedure3.draft_revision.types_de_champ.first }

      before { post :create_simple_routing, params: { procedure_id: procedure3.id, create_simple_routing: { stable_id: epci_tdc.stable_id } } }

      it do
        expect(response).to redirect_to(admin_procedure_groupe_instructeurs_path(procedure3))
        expect(flash.notice).to eq 'Les groupes instructeurs ont été ajoutés'
        expect(procedure3.groupe_instructeurs.pluck(:label)).to include("01 – Ain")
        expect(procedure3.reload.defaut_groupe_instructeur.routing_rule).to eq(ds_in_departement(champ_value(epci_tdc.stable_id), constant('01')))
        expect(procedure3.routing_enabled).to be_truthy
      end
    end
  end

  context 'with a commune_de_polynesie type de champ' do
    let!(:procedure3) do
      create(:procedure,
             types_de_champ_public: [{ type: :commune_de_polynesie }],
             administrateurs: [admin])
    end

    let!(:commune_de_polynesie_tdc) { procedure3.draft_revision.types_de_champ.first }

    before { post :create_simple_routing, params: { procedure_id: procedure3.id, create_simple_routing: { stable_id: commune_de_polynesie_tdc.stable_id } } }

    it do
      expect(response).to redirect_to(admin_procedure_groupe_instructeurs_path(procedure3))
      expect(flash.notice).to eq 'Les groupes instructeurs ont été ajoutés'
      expect(procedure3.groupe_instructeurs.pluck(:label)).to include("Australes")
      expect(procedure3.reload.defaut_groupe_instructeur.routing_rule).to eq(ds_in_archipel(champ_value(commune_de_polynesie_tdc.stable_id), constant('Australes')))
      expect(procedure3.routing_enabled).to be_truthy
    end
  end

  context 'with a code_postal_de_polynesie type de champ' do
    let!(:procedure3) do
      create(:procedure,
             types_de_champ_public: [{ type: :code_postal_de_polynesie }],
             administrateurs: [admin])
    end

    let!(:code_postal_de_polynesie_tdc) { procedure3.draft_revision.types_de_champ.first }

    before { post :create_simple_routing, params: { procedure_id: procedure3.id, create_simple_routing: { stable_id: code_postal_de_polynesie_tdc.stable_id } } }

    it do
      expect(response).to redirect_to(admin_procedure_groupe_instructeurs_path(procedure3))
      expect(flash.notice).to eq 'Les groupes instructeurs ont été ajoutés'
      expect(procedure3.groupe_instructeurs.pluck(:label)).to include("Australes")
      expect(procedure3.reload.defaut_groupe_instructeur.routing_rule).to eq(ds_in_archipel(champ_value(code_postal_de_polynesie_tdc.stable_id), constant('Australes')))
      expect(procedure3.routing_enabled).to be_truthy
    end
  end

  describe '#wizard' do
    let!(:procedure4) do
      create(:procedure,
             types_de_champ_public: [
               { type: :drop_down_list, libelle: 'Votre ville', options: ['Paris', 'Lyon', 'Marseille'] },
               { type: :text, libelle: 'Un champ texte' }
             ],
             administrateurs: [admin])
    end

    let!(:drop_down_tdc) { procedure4.draft_revision.types_de_champ.first }

    before { patch :wizard, params: { procedure_id: procedure4.id, choice: { state: 'routage_custom' } } }

    it do
      expect(response).to redirect_to(admin_procedure_groupe_instructeurs_path(procedure4))
      expect(procedure4.groupe_instructeurs.pluck(:label)).to match_array(['défaut', 'défaut bis'])
      expect(procedure4.reload.routing_enabled).to be_truthy
    end
  end

  describe '#add_signature' do
    let(:signature) { fixture_file_upload('spec/fixtures/files/black.png', 'image/png') }

    before {
      post :add_signature,
      params: {
        procedure_id: procedure.id,
        id: gi_1_1.id,
        groupe_instructeur: {
          signature: signature
        }
      }
    }

    it do
      expect(response).to redirect_to(admin_procedure_groupe_instructeur_path(procedure, gi_1_1))
      expect(gi_1_1.signature).to be_attached
    end
  end
end
