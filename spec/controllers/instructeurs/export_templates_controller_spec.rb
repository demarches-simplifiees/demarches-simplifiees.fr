describe Instructeurs::ExportTemplatesController, type: :controller do

  before { sign_in(instructeur.user) }

  describe '#create' do
    let(:instructeur) { create(:instructeur) }
    let(:procedure) { create(:procedure, instructeurs: [ instructeur ]) }
    let(:groupe_instructeur) { procedure.defaut_groupe_instructeur }
    let(:subject) { post :create, params: { procedure_id: procedure.id, groupe_id: groupe_instructeur.id, export_template: export_template_params } }

    context 'without default dossier directory' do
      let(:export_template_params) { { name: 'Mon Export'} }
      it 'display error notification' do
        subject
        expect(flash.alert).to be_present
      end
    end
  end
end

