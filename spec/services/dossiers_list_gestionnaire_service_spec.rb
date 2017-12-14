require 'spec_helper'

describe DossiersListGestionnaireService do
  let(:gestionnaire) { create :gestionnaire }
  let(:preference_smart_listing_page) { gestionnaire.preference_smart_listing_page }
  let(:liste) { 'all_state' }
  let(:dossier) { create :dossier }
  let(:accompagnateur_service) { AccompagnateurService.new gestionnaire, procedure, 'assign' }

  describe '#default_sort' do
    let(:procedure) { dossier.procedure }

    before do
      accompagnateur_service.change_assignement!
      accompagnateur_service.build_default_column

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
                                               .find_by(table: table, attr: attr, procedure: nil)
    }

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

  describe '#add_filter' do
    let(:table) { 'entreprise' }
    let(:attr) { 'raison_sociale' }
    let(:filter_value) { 'plop' }

    let(:select_preference_list_dossier) { gestionnaire.preference_list_dossiers
                                               .find_by(table: table, attr: attr, procedure: nil)
    }

    subject { described_class.new(gestionnaire, liste).add_filter new_filter }

    describe 'with one or two params in filter' do
      before do
        subject
        gestionnaire.reload
      end

      context 'when sort_params as table and attr' do
        let(:new_filter) { ({"#{table}.#{attr}" => filter_value}) }

        it { expect(select_preference_list_dossier.filter).to eq filter_value }
      end

      context 'when sort_params as no table' do
        let(:new_filter) { ({"#{attr}" => filter_value}) }
        let(:table) { nil }
        let(:attr) { 'id' }

        it { expect(select_preference_list_dossier.filter).to eq filter_value }
      end
    end
  end

  describe '#join_filter' do
    subject { DossiersListGestionnaireService.new(gestionnaire, liste, nil).joins_filter }

    it { is_expected.to eq []}

    context 'when a filter is fielded' do
      before do
        gestionnaire.preference_list_dossiers
            .find_by(table: 'entreprise', attr: 'raison_sociale', procedure: nil)
            .update_column :filter, 'plop'
      end

      it { is_expected.to eq [:entreprise] }
    end

    context 'when a filter is empty' do
      before do
        gestionnaire.preference_list_dossiers
            .find_by(table: 'entreprise', attr: 'raison_sociale', procedure: nil)
            .update_column :filter, ''
      end

      it { is_expected.to eq [] }
    end

    context 'when a filter is nil' do
      before do
        gestionnaire.preference_list_dossiers
            .find_by(table: 'entreprise', attr: 'raison_sociale', procedure: nil)
            .update_column :filter, nil
      end

      it { is_expected.to eq [] }
    end
  end

  describe '#where_filter' do
    before do
      gestionnaire.preference_list_dossiers
          .find_by(table: 'entreprise', attr: 'raison_sociale', procedure: nil)
          .update_column :filter, 'plop'

      gestionnaire.preference_list_dossiers
          .find_by(table: nil, attr: 'id', procedure: nil)
          .update_column :filter, '23'
    end

    subject { DossiersListGestionnaireService.new(gestionnaire, liste, nil).where_filter }

    it { is_expected.to eq "CAST(dossiers.id as TEXT) LIKE '%23%' AND CAST(entreprises.raison_sociale as TEXT) LIKE '%plop%'" }

    context 'when last filter caractere is *' do
      before do
        gestionnaire.preference_list_dossiers
            .find_by(table: 'entreprise', attr: 'raison_sociale', procedure: nil)
            .update_column :filter, 'plop*'
      end

      it { is_expected.to eq "CAST(dossiers.id as TEXT) LIKE '%23%' AND CAST(entreprises.raison_sociale as TEXT) LIKE 'plop%'" }
    end

    context 'when first filter caractere is *' do
      before do
        gestionnaire.preference_list_dossiers
            .find_by(table: nil, attr: 'id', procedure: nil)
            .update_column :filter, '*23'
      end

      it { is_expected.to eq "CAST(dossiers.id as TEXT) LIKE '%23' AND CAST(entreprises.raison_sociale as TEXT) LIKE '%plop%'" }
    end

    context 'when * caractere is presente' do
      before do
        gestionnaire.preference_list_dossiers
            .find_by(table: 'entreprise', attr: 'raison_sociale', procedure: nil)
            .update_column :filter, 'plop*plip'
      end

      it { is_expected.to eq "CAST(dossiers.id as TEXT) LIKE '%23%' AND CAST(entreprises.raison_sociale as TEXT) LIKE 'plop%plip'" }
    end

    context "when filter containe the character <'> " do
      before do
        gestionnaire.preference_list_dossiers
            .find_by(table: 'entreprise', attr: 'raison_sociale', procedure: nil)
            .update_column :filter, "MCDONALD'S FRANCE"
      end

      it { is_expected.to eq "CAST(dossiers.id as TEXT) LIKE '%23%' AND CAST(entreprises.raison_sociale as TEXT) LIKE '%MCDONALD''S FRANCE%'" }
    end

    context "when filter is empty " do
      before do
        gestionnaire.preference_list_dossiers
            .find_by(table: 'entreprise', attr: 'raison_sociale', procedure: nil)
            .update_column :filter, ""
      end

      it { is_expected.to eq "CAST(dossiers.id as TEXT) LIKE '%23%'" }
    end

    context 'when preference list contain a champ' do
      before do
        create :preference_list_dossier,
          gestionnaire: gestionnaire,
          table: 'champs',
          attr: '34',
          attr_decorate: '',
          filter: 'plop',
          procedure_id: create(:procedure)
      end

      it { is_expected.to eq "CAST(dossiers.id as TEXT) LIKE '%23%' AND CAST(entreprises.raison_sociale as TEXT) LIKE '%plop%' AND champs.type_de_champ_id = 34 AND CAST(champs.value as TEXT) LIKE '%plop%'" }
    end
  end

  describe '#default_page' do
    let(:page) { 2 }
    let(:procedure) { nil }

    before do
      preference_smart_listing_page.update page: page, liste: 'a_traiter'
    end

    subject { described_class.new(gestionnaire, liste, procedure).default_page }

    context 'when liste and procedure match with the actual preference' do
      let(:liste) { 'a_traiter' }

      it { is_expected.to eq 2 }
    end

    context 'when liste and procedure does not match with the actual preference' do
      let(:liste) { 'en_attente' }

      it { is_expected.to eq 1 }
    end
  end

  describe '#change_page!' do
    let(:procedure) { nil }
    let(:liste) { 'all_state' }

    let(:page) { 2 }
    let(:new_page) { 1 }

    before do
      preference_smart_listing_page.update page: page, liste: liste, procedure: nil
      subject
      preference_smart_listing_page.reload
    end

    subject { described_class.new(gestionnaire, liste, procedure).change_page! new_page }

    context 'when liste and procedure does not change' do
      it { expect(preference_smart_listing_page.liste).to eq liste }
      it { expect(preference_smart_listing_page.procedure).to eq procedure }
      it { expect(preference_smart_listing_page.page).to eq new_page }

      context 'when new_page is nil' do
        let(:new_page) { nil }

        it { expect(preference_smart_listing_page.liste).to eq liste }
        it { expect(preference_smart_listing_page.procedure).to eq procedure }
        it { expect(preference_smart_listing_page.page).to eq page }
      end
    end

    context 'when liste change' do
      let(:liste) { 'all_state' }

      it { expect(preference_smart_listing_page.liste).to eq liste }
      it { expect(preference_smart_listing_page.procedure).to eq procedure }
      it { expect(preference_smart_listing_page.page).to eq new_page }

      context 'when new_page is nil' do
        let(:new_page) { nil }

        it { expect(preference_smart_listing_page.liste).to eq liste }
        it { expect(preference_smart_listing_page.procedure).to eq procedure }
        it { expect(preference_smart_listing_page.page).to eq page }
      end
    end

    context 'when procedure change' do
      let(:procedure) { dossier.procedure }

      it { expect(preference_smart_listing_page.liste).to eq liste }
      it { expect(preference_smart_listing_page.procedure).to eq procedure }
      it { expect(preference_smart_listing_page.page).to eq new_page }

      context 'when new_page is nil' do
        let(:new_page) { nil }

        it { expect(preference_smart_listing_page.liste).to eq liste }
        it { expect(preference_smart_listing_page.procedure).to eq procedure }
        it { expect(preference_smart_listing_page.page).to eq 1 }
      end
    end

    context 'when procedure and liste change' do
      let(:liste) { 'all_state' }
      let(:procedure) { dossier.procedure }

      it { expect(preference_smart_listing_page.liste).to eq liste }
      it { expect(preference_smart_listing_page.procedure).to eq procedure }
      it { expect(preference_smart_listing_page.page).to eq new_page }

      context 'when new_page is nil' do
        let(:new_page) { nil }

        it { expect(preference_smart_listing_page.liste).to eq liste }
        it { expect(preference_smart_listing_page.procedure).to eq procedure }
        it { expect(preference_smart_listing_page.page).to eq 1 }
      end
    end
  end

  describe 'state filter methods' do
    let!(:procedure) { create :procedure }
    let!(:dossier) { create(:dossier, procedure: procedure, state: 'draft') }
    let!(:dossier2) { create(:dossier, procedure: procedure, state: 'en_construction') } #nouveaux
    let!(:dossier3) { create(:dossier, procedure: procedure, state: 'en_construction') } #nouveaux
    let!(:dossier6) { create(:dossier, procedure: procedure, state: 'received') } #a_instruire
    let!(:dossier7) { create(:dossier, procedure: procedure, state: 'received') } #a_instruire
    let!(:dossier8) { create(:dossier, procedure: procedure, state: 'closed') } #termine
    let!(:dossier9) { create(:dossier, procedure: procedure, state: 'refused') } #termine
    let!(:dossier10) { create(:dossier, procedure: procedure, state: 'without_continuation') } #termine
    let!(:dossier11) { create(:dossier, procedure: procedure, state: 'closed') } #termine
    let!(:dossier12) { create(:dossier, procedure: procedure, state: 'en_construction', archived: true) } #a_traiter #archived
    let!(:dossier14) { create(:dossier, procedure: procedure, state: 'closed', archived: true) } #termine #archived

    describe '#termine' do
      subject { DossiersListGestionnaireService.new(gestionnaire, liste, procedure).termine }

      it { expect(subject.size).to eq(4) }
      it { expect(subject).to include(dossier8, dossier9, dossier10, dossier11) }
    end

    describe '#a_instruire' do
      subject { DossiersListGestionnaireService.new(gestionnaire, liste, procedure).a_instruire }

      it { expect(subject.size).to eq(2) }
      it { expect(subject).to include(dossier6, dossier7) }
    end
  end
end
