describe Administrateurs::DossierSubmittedMessagesController, type: :controller do
   let(:administrateur) { create(:administrateur) }

   before { sign_in(administrateur.user) }

   describe '#create' do
     context 'when procedure is not published' do
       let(:procedure) { create(:procedure, administrateur: administrateur) }

       it 'creates a DossierSubmittedMessage on draft_revision' do
         message_on_submit_by_usager = "hello"
         expect {
           post(:create, params: { procedure_id: procedure.id, dossier_submitted_message: { message_on_submit_by_usager: message_on_submit_by_usager } })
         }.to change { DossierSubmittedMessage.count }.by(1)
         expect(response).to redirect_to admin_procedure_path(procedure)
         expect(procedure.reload.draft_revision.dossier_submitted_message).to eq(DossierSubmittedMessage.first)
       end
     end

     context 'when procedure is published' do
       let(:procedure) { create(:procedure, :published, administrateur: administrateur) }

       it 'creates a DossierSubmittedMessage on published_revision' do
          message_on_submit_by_usager = "hello"
          expect {
            post(:create, params: { procedure_id: procedure.id, dossier_submitted_message: { message_on_submit_by_usager: message_on_submit_by_usager } })
          }.to change { DossierSubmittedMessage.count }.by(1)
          expect(response).to redirect_to admin_procedure_path(procedure)
          expect(procedure.reload.published_revision.dossier_submitted_message).to eq(DossierSubmittedMessage.first)
        end
     end
   end

   describe '#edit' do
     context 'when procedure is draft and have a DossierSubmittedMessage' do
       let(:procedure) { create(:procedure, :with_dossier_submitted_message, administrateur: administrateur) }

       it 'assigns the existing DossierSubmittedMessage' do
         get(:edit, params: { procedure_id: procedure.id })
         expect(response).to have_http_status(200)
         expect(assigns(:dossier_submitted_message)).to eq(procedure.active_dossier_submitted_message)
       end
     end

     context 'when draft procedure does not have dossier_submitted_message' do
       let(:procedure) { create(:procedure, administrateur: administrateur) }

       it 'builds a new DossierSubmittedMessage' do
         get(:edit, params: { procedure_id: procedure.id })
         expect(response).to have_http_status(200)
         expect(assigns(:dossier_submitted_message).persisted?).to eq(false)
         expect(assigns(:dossier_submitted_message)).to be_an_instance_of(DossierSubmittedMessage)
       end
     end
   end

   describe '#update' do
     context 'when procedure is draft' do
       let(:procedure) { create(:procedure, :with_dossier_submitted_message, administrateur: administrateur) }

       it 'updates the existing DossierSubmittedMessage on draft_revision' do
         new_message_on_submit_by_usager = "hello"
         patch(:update, params: { procedure_id: procedure.id, dossier_submitted_message: { message_on_submit_by_usager: new_message_on_submit_by_usager } })
         expect(response).to redirect_to admin_procedure_path(procedure)
         expect(procedure.draft_revision.dossier_submitted_message.message_on_submit_by_usager).to eq(new_message_on_submit_by_usager)
       end
     end

     context 'when draft procedure is published' do
       let(:procedure) { create(:procedure, :published, :with_dossier_submitted_message, administrateur: administrateur) }
       it 'updates the existing DossierSubmittedMessage on published_revision' do
         new_message_on_submit_by_usager = "hello"
         patch(:update, params: { procedure_id: procedure.id, dossier_submitted_message: { message_on_submit_by_usager: new_message_on_submit_by_usager } })
         expect(response).to redirect_to admin_procedure_path(procedure)
         expect(procedure.published_revision.dossier_submitted_message.message_on_submit_by_usager).to eq(new_message_on_submit_by_usager)
       end
     end
   end
 end
