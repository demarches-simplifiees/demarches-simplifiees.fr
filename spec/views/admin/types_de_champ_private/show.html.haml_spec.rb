require 'spec_helper'

describe 'admin/types_de_champ/show.html.haml', type: :view do
  let(:procedure) { create(:procedure) }

  describe 'fields sorted' do
    let(:first_libelle) { 'salut la compagnie' }
    let(:last_libelle) { 'je suis bien sur la page' }
    let!(:type_de_champ_1) { create(:type_de_champ, :private, procedure: procedure, order_place: 1, libelle: last_libelle) }
    let!(:type_de_champ_0) { create(:type_de_champ, :private, procedure: procedure, order_place: 0, libelle: first_libelle) }
    before do
      procedure.reload
      assign(:procedure, procedure)
      assign(:types_de_champ_facade, AdminTypesDeChampFacades.new(true, procedure))
      render
    end
    it 'sorts by order place' do
      expect(rendered).to match(/#{first_libelle}.*#{last_libelle}/m)
    end
  end

  describe 'elements presents or not' do
    subject do
      procedure.reload
      assign(:procedure, procedure)
      assign(:types_de_champ_facade, AdminTypesDeChampFacades.new(true, procedure))
      render
      rendered
    end

    describe 'mandatory checkbox' do
      it 'no mandatory checkbox are present' do
        expect(subject).to have_css('.form-group.mandatory[style*="visibility: hidden"]')
      end
    end

    describe 'arrow button' do
      context 'when there is no field in database' do
        it { expect(subject).not_to have_css('.fa-chevron-down') }
        it { expect(subject).not_to have_css('.fa-chevron-up') }
      end
      context 'when there is only one field in database' do
        let!(:type_de_champ_0) { create(:type_de_champ, :private, procedure: procedure, order_place: 0) }
        it { expect(subject).to have_css('#btn_down_0[style*="visibility: hidden"]') }
        it { expect(subject).to have_css('#btn_up_0[style*="visibility: hidden"]')   }
        it { expect(subject).not_to have_css('#btn_up_1')   }
        it { expect(subject).not_to have_css('#btn_down_1') }
      end
      context 'when there are 2 fields in database' do
        let!(:type_de_champ_0) { create(:type_de_champ, :private, procedure: procedure, order_place: 0) }
        let!(:type_de_champ_1) { create(:type_de_champ, :private, procedure: procedure, order_place: 1) }
        it { expect(subject).to have_css('#btn_down_0') }
        it { expect(subject).to have_css('#btn_up_0[style*="visibility: hidden"]') }
        it { expect(subject).to have_css('#btn_up_1') }
        it { expect(subject).to have_css('#btn_down_1[style*="visibility: hidden"]') }
      end
    end
  end
end
