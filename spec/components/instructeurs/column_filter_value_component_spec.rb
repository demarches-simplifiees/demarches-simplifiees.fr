# frozen_string_literal: true

describe Instructeurs::ColumnFilterValueComponent, type: :component do
  let(:component) { described_class.new(column:) }
  let(:instructeur) { create(:instructeur) }
  let(:procedure) { create(:procedure, instructeurs: [instructeur]) }
  let(:procedure_id) { procedure.id }

  before do
    allow(component).to receive(:current_instructeur).and_return(instructeur)
  end

  describe '.options_for_select_of_column' do
    subject { component.send(:options_for_select_of_column) }

    context "column is groupe_instructeur" do
      let(:column) { double("Column", scope: nil, table: 'groupe_instructeur', h_id: { procedure_id: }) }
      let!(:gi_2) { instructeur.groupe_instructeurs.create(label: 'gi2', procedure:) }
      let!(:gi_3) { instructeur.groupe_instructeurs.create(label: 'gi3', procedure: create(:procedure)) }

      it { is_expected.to eq([['défaut', procedure.defaut_groupe_instructeur.id], ['gi2', gi_2.id]]) }
    end

    context 'when column is dropdown' do
      let(:types_de_champ_public) { [{ type: :drop_down_list, libelle: 'Votre ville', options: ['Paris', 'Lyon', 'Marseille'] }] }
      let(:procedure) { create(:procedure, :published, types_de_champ_public:) }
      let(:drop_down_stable_id) { procedure.active_revision.types_de_champ.first.stable_id }
      let(:column) { procedure.find_column(label: 'Votre ville') }

      it 'find most recent tdc' do
        is_expected.to eq(['Paris', 'Lyon', 'Marseille'])
      end
    end
  end
end
