describe RoutingEngine, type: :model do
  include Logic

  before { Flipper.enable(:routing_rules, procedure) }

  describe '.compute' do
    let(:procedure) do
      create(:procedure).tap do |p|
          p.groupe_instructeurs.create(label: 'a second group')
          p.groupe_instructeurs.create(label: 'a third group')
        end
    end

    let(:dossier) { create(:dossier, procedure:) }
    let(:defaut_groupe) { procedure.defaut_groupe_instructeur }
    let(:gi_2) { procedure.groupe_instructeurs.find_by(label: 'a second group') }

    subject do
      RoutingEngine.compute(dossier)
      dossier.groupe_instructeur
    end

    context 'without any rules' do
      it { is_expected.to eq(defaut_groupe) }
    end

    context 'without any matching rules' do
      before do
        procedure.groupe_instructeurs.each do |gi|
          gi.update(routing_rule: constant(false))
        end
      end

      it { is_expected.to eq(defaut_groupe) }
    end

    context 'with a matching rules' do
      before { gi_2.update(routing_rule: constant(true)) }

      it { is_expected.to eq(gi_2) }
    end

    context 'with a closed gi with a matching rules' do
      before { gi_2.update(routing_rule: constant(true), closed: true) }

      it { is_expected.to eq(defaut_groupe) }
    end
  end
end
