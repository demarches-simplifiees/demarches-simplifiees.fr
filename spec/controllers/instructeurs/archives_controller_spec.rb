describe Instructeurs::ArchivesController, type: :controller do
  let(:procedure1) { create(:procedure, :published, groupe_instructeurs: [gi1]) }
  let(:procedure2) { create(:procedure, :published, groupe_instructeurs: [gi2]) }
  let!(:instructeur) { create(:instructeur, groupe_instructeurs: [gi1, gi2]) }
  let!(:archive1) { create(:archive, :generated, groupe_instructeurs: [gi1]) }
  let!(:archive2) { create(:archive, :generated, groupe_instructeurs: [gi2]) }
  let(:gi1) { create(:groupe_instructeur) }
  let(:gi2) { create(:groupe_instructeur) }

  before do
    sign_in(instructeur.user)
  end

  after { Timecop.return }

  describe '#index' do
    before do
      create_dossier_for_month(procedure1, 2021, 3)
      create_dossier_for_month(procedure1, 2021, 3)
      create_dossier_for_month(procedure1, 2021, 2)
      Timecop.freeze(Time.zone.local(2021, 3, 5))
    end

    it 'displays archives' do
      get :index, params: { procedure_id: procedure1.id }

      expect(assigns(:archives)).to eq([archive1])
    end
  end

  describe '#create' do
    let(:month) { '21-03' }
    let(:date_month) { Date.strptime(month, "%Y-%m") }
    let(:subject) do
      post :create, params: { procedure_id: procedure1.id, type: 'monthly', month: month }
    end

    it "performs archive creation job" do
      expect { subject }.to have_enqueued_job(ArchiveCreationJob).with(procedure1, an_instance_of(Archive), instructeur)
      expect(flash.notice).to include("Votre demande a été prise en compte")
    end
  end

  private

  def create_dossier_for_month(procedure, year, month)
    Timecop.freeze(Time.zone.local(year, month, 5))
    create(:dossier, :accepte, :with_attestation, procedure: procedure)
  end
end
