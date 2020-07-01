describe Admin::InstructeursController, type: :controller do
  let(:admin) { create(:administrateur) }
  let(:email_2) { 'plip@octo.com' }
  let(:admin_2) { create :administrateur, email: email_2 }

  before do
    sign_in(admin.user)
  end

  describe 'GET #index' do
    subject { get :index }
    it { expect(subject.status).to eq(200) }
  end

  describe 'GET #index with sorting and pagination' do
    subject {
      get :index, params: {
        'instructeurs_smart_listing[page]': 1,
        'instructeurs_smart_listing[per_page]': 10,
        'instructeurs_smart_listing[sort][email]': 'asc'
      }
    }

    it { expect(subject.status).to eq(200) }
  end

  describe 'POST #create' do
    let(:email) { 'test@plop.com' }
    let(:procedure_id) { nil }
    subject { post :create, params: { instructeur: { email: email }, procedure_id: procedure_id } }

    context 'When email is valid' do
      before do
        subject
      end

      let(:instructeur) { Instructeur.last }

      it { expect(response.status).to eq(302) }
      it { expect(response).to redirect_to admin_instructeurs_path }

      context 'when procedure_id params is not null' do
        let(:procedure) { create :procedure }
        let(:procedure_id) { procedure.id }
        it { expect(response.status).to eq(302) }
        it { expect(response).to redirect_to procedure_groupe_instructeur_path(procedure, procedure.defaut_groupe_instructeur) }
      end

      describe 'Instructeur attributs in database' do
        it { expect(instructeur.email).to eq(email) }
      end

      describe 'New instructeur is assign to the admin' do
        it { expect(instructeur.administrateurs).to include admin }
        it { expect(admin.instructeurs).to include instructeur }
      end
    end

    context 'when email is not valid' do
      before do
        subject
      end
      let(:email) { 'piou' }
      it { expect(response.status).to eq(302) }
      it { expect { response }.not_to change(Instructeur, :count) }
      it { expect(flash[:alert]).to be_present }

      describe 'Email Notification' do
        it {
          expect(InstructeurMailer).not_to receive(:new_instructeur)
          expect(InstructeurMailer).not_to receive(:deliver_later)
          subject
        }
      end
    end

    context 'when email is empty' do
      before do
        subject
      end
      let(:email) { '' }
      it { expect(response.status).to eq(302) }
      it { expect { response }.not_to change(Instructeur, :count) }

      it 'Notification email is not send' do
        expect(InstructeurMailer).not_to receive(:new_instructeur)
        expect(InstructeurMailer).not_to receive(:deliver_later)
      end
    end

    context 'when email is already assign at the admin' do
      before do
        create :instructeur, email: email, administrateurs: [admin]
        subject
      end

      it { expect(response.status).to eq(302) }
      it { expect { response }.not_to change(Instructeur, :count) }
      it { expect(flash[:alert]).to be_present }

      describe 'Email notification' do
        it 'is not sent when email already exists' do
          expect(InstructeurMailer).not_to receive(:new_instructeur)
          expect(InstructeurMailer).not_to receive(:deliver_later)

          subject
        end
      end
    end

    context 'when an other admin will add the same email' do
      let(:instructeur) { Instructeur.by_email(email) }

      before do
        create :instructeur, email: email, administrateurs: [admin]

        sign_out(admin.user)
        sign_in(admin_2.user)

        subject
      end

      it { expect(response.status).to eq(302) }
      it { expect { response }.not_to change(Instructeur, :count) }
      it { expect(flash[:notice]).to be_present }

      it { expect(admin_2.instructeurs).to include instructeur }
      it { expect(instructeur.administrateurs.size).to eq 2 }
    end

    context 'when an other admin will add the same email with some uppercase in it' do
      let(:email) { 'Test@Plop.com' }
      let(:instructeur) { Instructeur.by_email(email.downcase) }

      before do
        create :instructeur, email: email, administrateurs: [admin]

        sign_out(admin.user)
        sign_in(admin_2.user)

        subject
      end

      it { expect(admin_2.instructeurs).to include instructeur }
    end

    context 'Email notification' do
      it 'Notification email is sent when instructeur is create' do
        expect_any_instance_of(User).to receive(:invite!)
        subject
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:email) { 'test@plop.com' }
    let!(:admin) { create :administrateur }
    let!(:instructeur) { create :instructeur, email: email, administrateurs: [admin] }

    subject { delete :destroy, params: { id: instructeur.id } }

    context "when gestionaire_id is valid" do
      before do
        subject
        admin.reload
        instructeur.reload
      end

      it { expect(response.status).to eq(302) }
      it { expect(response).to redirect_to admin_instructeurs_path }
      it { expect(admin.instructeurs).not_to include instructeur }
      it { expect(instructeur.administrateurs).not_to include admin }
    end

    it { expect { subject }.not_to change(Instructeur, :count) }
  end
end
