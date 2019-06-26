describe '20190625181922_normalize_prenom_list' do
  let(:dossiers) {
    [
      create(:dossier, individual: create(:individual, nom: 'lefèvre', prenom: 'ADÉLAIDE')),
      create(:dossier, individual: create(:individual, nom: 'de la tourandière', prenom: 'ANNE GAELLE')),
      create(:dossier, individual: create(:individual, nom: 'Lalumière-Dufour', prenom: 'ANNE-GAELLE')),
      create(:dossier, individual: create(:individual, nom: "D'Ornano", prenom: 'franÇois-jean')),
      create(:dossier, individual: create(:individual, nom: "de la fayette", prenom: 'gilbert')),
      create(:dossier, individual: create(:individual, nom: " Noël ", prenom: ' arthur, gilbert andré,  roger '))
    ]
  }
  let(:rake_task) { Rake::Task['after_party:normalize_prenom_list'] }

  before do
    dossiers
    rake_task.invoke
  end

  after { rake_task.reenable }

  it 'normalize noms et prenom' do
    expect(dossiers.map { |dossier| dossier.individual.reload.prenom }).to eq(['Adélaide', 'Anne Gaelle', 'Anne-Gaelle', "François-Jean", "Gilbert", 'Arthur, Gilbert André, Roger'])
  end
end
