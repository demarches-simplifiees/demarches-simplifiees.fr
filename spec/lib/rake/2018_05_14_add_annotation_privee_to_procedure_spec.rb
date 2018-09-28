describe '2018_05_14_add_annotation_privee_to_procedure' do
  let!(:user) { create(:user) }
  let!(:procedure) do
    procedure = create(:procedure)
    10.times do |i|
      TypeDeChamp.create(
        procedure: procedure,
        private: false,
        libelle: 'libelle',
        order_place: i,
        type_champ: 'number'
      )

      TypeDeChamp.create(
        procedure: procedure,
        private: true,
        libelle: 'libelle',
        order_place: i,
        type_champ: 'number'
      )
    end
    procedure
  end
  let!(:dossier) { Dossier.create(procedure: procedure, user: user, state: 'brouillon') }
  let(:rake_task) { Rake::Task['2018_05_14_add_annotation_privee_to_procedure:add'] }

  before do
    ENV['PROCEDURE_ID'] = procedure.id.to_s
    rake_task.invoke
    procedure.reload
  end

  after { rake_task.reenable }

  it { expect(procedure.types_de_champ.count).to eq(10) }
  it { expect(procedure.types_de_champ_private.count).to eq(11) }
  it { expect(dossier.champs_private.includes(:type_de_champ).map(&:order_place).sort).to match((0..10).to_a) }
  it { expect(procedure.types_de_champ_private.find_by(order_place: 7).type_champ).to eq('text') }
end
