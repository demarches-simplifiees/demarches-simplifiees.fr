describe RoutingEngine, type: :model do
  include Logic

  describe '.compute' do
    let(:dossier) { create(:dossier, procedure:) }
    let(:defaut_groupe) { procedure.defaut_groupe_instructeur }
    let(:gi_2) { procedure.groupe_instructeurs.create(label: 'a second group') }

    subject do
      RoutingEngine.compute(dossier)
      dossier.groupe_instructeur
    end

    context 'with a drop down list type de champ' do
      let(:procedure) do
        create(:procedure,
          types_de_champ_public: [{ type: :drop_down_list, libelle: 'Votre ville', options: ['Paris', 'Lyon', 'Marseille'] }]).tap do |p|
          p.groupe_instructeurs.create(label: 'a third group')
        end
      end

      let(:drop_down_tdc) { procedure.draft_revision.types_de_champ.first }

      context 'without any rules' do
        it { is_expected.to eq(defaut_groupe) }
      end

      context 'without any matching rules' do
        before do
          procedure.groupe_instructeurs.each do |gi|
            gi.update(routing_rule: ds_eq(constant(false), constant(true)))
          end
        end

        it { is_expected.to eq(defaut_groupe) }
      end

      context 'with rules not configured yet' do
        before do
          procedure.groupe_instructeurs.each do |gi|
            gi.update(routing_rule: ds_eq(empty, empty))
          end
        end

        it { is_expected.to eq(defaut_groupe) }
      end

      context 'with a matching rule' do
        before do
          gi_2.update(routing_rule: ds_eq(champ_value(drop_down_tdc.stable_id), constant('Lyon')))
          dossier.champs.first.update(value: 'Lyon')
        end

        it { is_expected.to eq(gi_2) }
      end

      context 'with a closed gi with a matching rule' do
        before { gi_2.update(routing_rule: constant(true), closed: true) }

        it { is_expected.to eq(defaut_groupe) }
      end

      context 'with a non equals rule' do
        before do
          gi_2.update(routing_rule: ds_not_eq(champ_value(drop_down_tdc.stable_id), constant('Lyon')))
          dossier.champs.first.update(value: 'Paris')
        end

        it do
          is_expected.not_to eq(defaut_groupe)
          is_expected.to eq(gi_2)
        end
      end
    end

    context 'with a departements type de champ' do
      let(:procedure) do
        create(:procedure, types_de_champ_public: [{ type: :departements }]).tap do |p|
          p.groupe_instructeurs.create(label: 'a third group')
        end
      end

      let(:departements_tdc) { procedure.draft_revision.types_de_champ.first }

      context 'with a matching rule' do
        before do
          gi_2.update(routing_rule: ds_eq(champ_value(departements_tdc.stable_id), constant('43')))
          dossier.champs.first.update(value: 'Haute-Loire')
        end

        it { is_expected.to eq(gi_2) }
      end
    end

    context 'with a regions type de champ' do
      let(:procedure) do
        create(:procedure, types_de_champ_public: [{ type: :regions }]).tap do |p|
          p.groupe_instructeurs.create(label: 'a third group')
        end
      end

      let(:regions_tdc) { procedure.draft_revision.types_de_champ.first }

      context 'with a matching rule' do
        before do
          gi_2.update(routing_rule: ds_eq(champ_value(regions_tdc.stable_id), constant('04')))
          dossier.champs.first.update(value: 'La Réunion')
        end

        it { is_expected.to eq(gi_2) }
      end
    end

    context 'with a communes type de champ' do
      let(:procedure) do
        create(:procedure, types_de_champ_public: [{ type: :communes }]).tap do |p|
          p.groupe_instructeurs.create(label: 'a third group')
        end
      end

      let(:communes_tdc) { procedure.draft_revision.types_de_champ.first }

      context 'with a matching rule' do
        before do
          gi_2.update(routing_rule: ds_in_departement(champ_value(communes_tdc.stable_id), constant('92')))
          dossier.champs.first.update(code_postal: '92500', external_id: '92063')
        end

        it { is_expected.to eq(gi_2) }
      end
    end

    context 'with an epci type de champ' do
      let(:procedure) do
        create(:procedure, types_de_champ_public: [{ type: :epci }]).tap do |p|
          p.groupe_instructeurs.create(label: 'a third group')
        end
      end

      let(:epci_tdc) { procedure.draft_revision.types_de_champ.first }

      context 'with a matching rule' do
        before do
          gi_2.update(routing_rule: ds_in_departement(champ_value(epci_tdc.stable_id), constant('42')))
          dossier.champs.first.update_columns(
            external_id: 244200895,
            value: 'CC du Pilat Rhodanien',
            value_json: { code_departement: '42' }
          )
        end

        it do
          is_expected.to eq(gi_2)
        end
      end
    end

    context 'with a commune_de_polynesie type de champ' do
      let(:procedure) do
        create(:procedure, types_de_champ_public: [{ type: :commune_de_polynesie }]).tap do |p|
          p.groupe_instructeurs.create(label: 'a third group')
        end
      end

      let(:commune_de_polynesie_tdc) { procedure.draft_revision.types_de_champ.first }

      context 'with a matching rule' do
        before do
          gi_2.update(routing_rule: ds_in_archipel(champ_value(commune_de_polynesie_tdc.stable_id), constant('Tuamotu-Gambiers')))
          dossier.champs.first.update(value: 'Mangareva - 98755')
        end

        it { is_expected.to eq(gi_2) }
      end
    end

    context 'with a code_postal_de_polynesie type de champ' do
      let(:procedure) do
        create(:procedure, types_de_champ_public: [{ type: :code_postal_de_polynesie }]).tap do |p|
          p.groupe_instructeurs.create(label: 'a third group')
        end
      end

      let(:code_postal_de_polynesie_tdc) { procedure.draft_revision.types_de_champ.first }

      context 'with a matching rule' do
        before do
          gi_2.update(routing_rule: ds_in_archipel(champ_value(code_postal_de_polynesie_tdc.stable_id), constant('Tuamotu-Gambiers')))
          dossier.champs.first.update(value: '98755 - Mangareva')
        end

        it { is_expected.to eq(gi_2) }
      end
    end

    context 'routing rules priorities' do
      let(:procedure) do
        create(:procedure,
          types_de_champ_public: [{ type: :drop_down_list, libelle: 'Ville', options: ['Paris', 'Lyon', 'Marseille'] }]).tap do |p|
          p.groupe_instructeurs.create(label: 'c')
        end
      end

      let(:drop_down_tdc) { procedure.draft_revision.types_de_champ.first }

      let!(:gi_3) { procedure.groupe_instructeurs.find_by(label: 'c') }

      context 'not eq rule coming first' do
        before do
          defaut_groupe.update(label: 'a')
          gi_2.update(label: 'b', routing_rule: ds_not_eq(champ_value(drop_down_tdc.stable_id), constant('Lyon')))
          gi_3.update(routing_rule: ds_eq(champ_value(drop_down_tdc.stable_id), constant('Marseille')))
          dossier.champs.first.update(value: 'Marseille')
        end

        it 'computes by groups label order' do
          is_expected.to eq(gi_2)
        end
      end
    end
  end
end
