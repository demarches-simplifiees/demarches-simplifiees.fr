require 'spec_helper'

describe DossiersListGestionnaireService do
  let(:gestionnaire) { create :gestionnaire }
  let(:liste) { 'a_traiter' }
  let(:dossier) { create :dossier }

  describe '#default_sort' do
    let(:procedure) { dossier.procedure }

    before do
      AccompagnateurService.change_assignement! gestionnaire, procedure, 'assign'
      AccompagnateurService.build_default_column gestionnaire, procedure, 'assign'

      gestionnaire.reload
    end

    subject { DossiersListGestionnaireService.new(gestionnaire, liste, procedure).default_sort }

    context 'when gestionnaire does not have default sort' do
      it { is_expected.to eq({'nil' => 'nil'}) }
    end

    context 'when gestionnaire have default sort' do

      before do
        preference_attr.update_column(:order, 'asc')
      end

      context 'when default sort is a dossier attr' do
        let(:preference_attr) { gestionnaire.preference_list_dossiers.where(procedure: procedure, table: nil, attr: 'id').first }

        it { is_expected.to eq({"#{preference_attr.attr}" => "asc"}) }
      end

      context 'when default sort is not a dossier attr' do
        let(:preference_attr) { gestionnaire.preference_list_dossiers.where(procedure: procedure, table: 'entreprise', attr: 'raison_sociale').first }

        it { is_expected.to eq({"#{preference_attr.table}.#{preference_attr.attr}" => "asc"}) }
      end
    end
  end

  describe '#change_sort!' do
    let(:table) { 'entreprise' }
    let(:attr) { 'raison_sociale' }
    let(:order) { 'desc' }

    let(:select_preference_list_dossier) { gestionnaire.preference_list_dossiers
                                               .find_by(table: table, attr: attr, procedure: nil) }

    subject { DossiersListGestionnaireService.new(gestionnaire, liste).change_sort! param_sort }

    describe 'with one or two params in sort' do
      before do
        subject

        gestionnaire.reload
      end

      context 'when sort_params as table and attr' do
        let(:param_sort) { ({"#{table}.#{attr}" => order}) }

        it { expect(select_preference_list_dossier.order).to eq 'desc' }
      end

      context 'when sort_params as no table' do
        let(:param_sort) { ({"#{attr}" => order}) }
        let(:table) { nil }
        let(:attr) { 'id' }

        it { expect(select_preference_list_dossier.order).to eq 'desc' }
      end

    end

    context 'when procedure as already a preference order' do
      let(:param_sort) { ({"#{attr}" => order}) }
      let(:table) { nil }
      let(:attr) { 'id' }

      before do
        gestionnaire.preference_list_dossiers.find_by(procedure: nil, table: 'entreprise', attr: 'raison_sociale').update_column :order, :desc
      end

      it 'keep one order by procedure id' do
        expect(gestionnaire.preference_list_dossiers.where(procedure: nil).where.not(order: nil).size).to eq 1
        subject
        expect(gestionnaire.preference_list_dossiers.where(procedure: nil).where.not(order: nil).size).to eq 1
      end
    end
  end
end
