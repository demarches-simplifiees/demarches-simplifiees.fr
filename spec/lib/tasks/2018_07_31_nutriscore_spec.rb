require 'spec_helper'

describe '2018_07_31_nutriscore' do
  let(:gestionnaire) { create(:gestionnaire) }
  let(:proc_from) do
    proc_from = create(:procedure, :published)
    ((0..23).to_a - [1, 2, 9, 18]).each do |i|
      proc_from.types_de_champ << create(:type_de_champ_text, order_place: i, procedure: proc_from)
    end
    proc_from.types_de_champ << create(:type_de_champ_text, order_place: 9, libelle: 'Fonction', procedure: proc_from)
    proc_from.types_de_champ << create(:type_de_champ_header_section, order_place: 18, libelle: 'PARTIE 3 : ENGAGEMENT DE L’EXPLOITANT', procedure: proc_from)
    proc_from.save
    proc_from
  end
  let!(:type_champ_from) { create(:type_de_champ_textarea, order_place: 1, libelle: 'texte', procedure: proc_from) }
  let!(:type_champ_siret_from) { create(:type_de_champ_text, order_place: 2, libelle: 'Numéro SIRET', procedure: proc_from) }
  let!(:type_champ_fonction_from) {}

  let(:etablissement) { create(:etablissement) }
  let!(:dossier) { create(:dossier, procedure: proc_from, etablissement: etablissement) }

  let(:proc_to) do
    proc_to = create(:procedure, administrateur: proc_from.administrateur)
    ((0..17).to_a - [1, 2, 9]).each do |i|
      libelle = proc_from.types_de_champ.find_by(order_place: i).libelle
      proc_to.types_de_champ << create(:type_de_champ_text, order_place: i, libelle: libelle, procedure: proc_to)
    end
    proc_to.types_de_champ << create(:type_de_champ_header_section, order_place: 18, libelle: 'PARTIE 3 : ZONE GEOGRAPHIQUE', procedure: proc_to)
    proc_to.types_de_champ << create(
      :type_de_champ_multiple_drop_down_list,
      order_place: 19,
      libelle: 'Pays de commercialisation',
      drop_down_list: create(:drop_down_list, value: (Champs::PaysChamp.pays - ['----']).join("\r\n")),
      procedure: proc_to
    )
    proc_to.types_de_champ << create(:type_de_champ_header_section, order_place: 20, libelle: 'PARTIE 4 : ENGAGEMENT DE L’EXPLOITANT', procedure: proc_to)
    (21..25).each do |i|
      libelle = proc_from.types_de_champ.find_by(order_place: i - 2).libelle
      proc_to.types_de_champ << create(:type_de_champ_text, order_place: i, libelle: libelle, procedure: proc_to)
    end
    proc_to.save
    proc_to
  end
  let!(:type_champ_to) { create(:type_de_champ_textarea, order_place: 1, libelle: 'texte', procedure: proc_to) }
  let!(:type_champ_siret_to) { create(:type_de_champ_siret, order_place: 2, libelle: 'Numéro SIRET', procedure: proc_to) }
  let!(:type_champ_fonction_to) { create(:type_de_champ_text, order_place: 9, libelle: 'Fonction', mandatory: true, procedure: proc_to) }

  let(:rake_task) { Rake::Task['2018_07_31_nutriscore:migrate_dossiers'] }

  def run_task
    ENV['SOURCE_PROCEDURE_ID'] = proc_from.id.to_s
    ENV['DESTINATION_PROCEDURE_ID'] = proc_to.id.to_s
    rake_task.invoke
    dossier.reload
    proc_from.reload
    proc_to.reload
  end

  after { rake_task.reenable }

  context 'on happy path' do
    before do
      gestionnaire.assign_to_procedure(proc_from)
      run_task
    end

    it { expect(dossier.procedure).to eq(proc_to) }
    it { expect(dossier.champs.pluck(:type_de_champ_id)).to match_array(proc_to.types_de_champ.pluck(:id)) }
    it { expect(dossier.champs.find_by(type_de_champ: type_champ_siret_to).value).to eq(etablissement.siret) }
    it { expect(dossier.champs.find_by(type_de_champ: type_champ_siret_to).etablissement).to eq(etablissement) }
    it { expect(proc_from).to be_archivee }
    it { expect(proc_to).to be_publiee }
    it { expect(proc_to.gestionnaires).to eq([gestionnaire]) }
  end

  context 'detecting error conditions' do
    context 'with administrateur mismatch' do
      let(:proc_to) { create(:procedure) }

      it { expect { run_task }.to raise_exception(/^Mismatching administrateurs/) }
    end

    context 'with champ count mismatch' do
      before { create(:type_de_champ_textarea, order_place: 26, libelle: 'texte', procedure: proc_to) }

      it { expect { run_task }.to raise_exception('Incorrect destination size 27 (expected 26)') }
    end

    context 'with champ libelle mismatch' do
      let!(:type_champ_to) { create(:type_de_champ_textarea, order_place: 1, libelle: 'autre texte', procedure: proc_to) }

      it { expect { run_task }.to raise_exception(/incorrect libelle texte \(expected autre texte\)$/) }
    end

    context 'with champ type mismatch' do
      let!(:type_champ_to) { create(:type_de_champ_text, order_place: 1, libelle: 'texte', procedure: proc_to) }

      it { expect { run_task }.to raise_exception(/incorrect type champ textarea \(expected text\)$/) }
    end

    context 'with champ mandatoriness mismatch' do
      let!(:type_champ_to) { create(:type_de_champ_textarea, order_place: 1, libelle: 'texte', mandatory: true, procedure: proc_to) }

      it { expect { run_task }.to raise_exception(/champ should be mandatory$/) }
    end

    context 'with dropdown mismatch' do
      let!(:type_champ_from) { create(:type_de_champ_drop_down_list, order_place: 1, libelle: 'dropdown', drop_down_list: create(:drop_down_list, value: 'something'), procedure: proc_from) }
      let!(:type_champ_to) { create(:type_de_champ_drop_down_list, order_place: 1, libelle: 'dropdown', drop_down_list: create(:drop_down_list, value: 'something else'), procedure: proc_to) }

      it { expect { run_task }.to raise_exception(/incorrect drop down list \["", "something"\] \(expected \["", "something else"\]\)$/) }
    end

    context 'with siret mismatch on source' do
      let!(:type_champ_siret_from) { create(:type_de_champ_textarea, order_place: 2, libelle: 'Numéro SIRET', procedure: proc_from) }

      it { expect { run_task }.to raise_exception(/incorrect type champ textarea \(expected text\)$/) }
    end

    context 'with siret mismatch on destination' do
      let!(:type_champ_siret_to) { create(:type_de_champ_text, order_place: 2, libelle: 'Numéro SIRET', procedure: proc_to) }

      it { expect { run_task }.to raise_exception(/incorrect type champ text \(expected siret\)$/) }
    end
  end
end
