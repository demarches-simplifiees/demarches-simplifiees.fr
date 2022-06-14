describe Dossier do
  describe '#can_rebase?' do
    let(:procedure) { create(:procedure, :with_type_de_champ_mandatory, :with_yes_no, attestation_template: build(:attestation_template)) }
    let(:attestation_template) { procedure.draft_revision.attestation_template.find_or_revise! }
    let(:type_de_champ) { procedure.types_de_champ.find { |tdc| !tdc.mandatory? } }
    let(:mandatory_type_de_champ) { procedure.types_de_champ.find(&:mandatory?) }

    before { Flipper.enable(:procedure_revisions, procedure) }

    context 'en_construction' do
      let(:dossier) { create(:dossier, :en_construction, procedure: procedure) }

      before do
        procedure.publish!
        procedure.reload
        dossier
      end

      context 'with added type de champ' do
        before do
          procedure.draft_revision.add_type_de_champ({
            type_champ: TypeDeChamp.type_champs.fetch(:text),
            libelle: "Un champ text"
          })
          procedure.publish_revision!
          dossier.reload
        end

        it 'should be false' do
          expect(dossier.pending_changes).not_to be_empty
          expect(dossier.can_rebase?).to be_falsey
        end
      end

      context 'with type de champ made optional' do
        before do
          procedure.draft_revision.find_or_clone_type_de_champ(mandatory_type_de_champ.stable_id).update(mandatory: false)
          procedure.publish_revision!
          dossier.reload
        end

        it 'should be true' do
          expect(dossier.pending_changes).not_to be_empty
          expect(dossier.can_rebase?).to be_truthy
        end
      end

      context 'with type de champ made mandatory' do
        before do
          procedure.draft_revision.find_or_clone_type_de_champ(type_de_champ.stable_id).update(mandatory: true)
          procedure.publish_revision!
          dossier.reload
        end

        it 'should be false' do
          expect(dossier.pending_changes).not_to be_empty
          expect(dossier.can_rebase?).to be_falsey
        end
      end

      context 'with removed type de champ' do
        before do
          procedure.draft_revision.remove_type_de_champ(type_de_champ.stable_id)
          procedure.publish_revision!
          dossier.reload
        end

        it 'should be true' do
          expect(dossier.pending_changes).not_to be_empty
          expect(dossier.can_rebase?).to be_truthy
        end
      end

      context 'with attestation template changes' do
        before do
          attestation_template.update(title: "Test")
          procedure.publish_revision!
          dossier.reload
        end

        it 'should be true' do
          expect(dossier.pending_changes).not_to be_empty
          expect(dossier.can_rebase?).to be_truthy
        end
      end
    end

    context 'en_instruction' do
      let(:dossier) { create(:dossier, :en_instruction, procedure: procedure) }

      before do
        procedure.publish!
        procedure.reload
        dossier
      end

      context 'with added type de champ' do
        before do
          procedure.draft_revision.add_type_de_champ({
            type_champ: TypeDeChamp.type_champs.fetch(:text),
            libelle: "Un champ text"
          })
          procedure.publish_revision!
          dossier.reload
        end

        it 'should be false' do
          expect(dossier.pending_changes).not_to be_empty
          expect(dossier.can_rebase?).to be_falsey
        end
      end

      context 'with removed type de champ' do
        before do
          procedure.draft_revision.remove_type_de_champ(type_de_champ.stable_id)
          procedure.publish_revision!
          dossier.reload
        end

        it 'should be false' do
          expect(dossier.pending_changes).not_to be_empty
          expect(dossier.can_rebase?).to be_falsey
        end
      end

      context 'with attestation template changes' do
        before do
          attestation_template.update(title: "Test")
          procedure.publish_revision!
          dossier.reload
        end

        it 'should be true' do
          expect(dossier.pending_changes).not_to be_empty
          expect(dossier.can_rebase?).to be_truthy
        end
      end

      context 'with type de champ made optional' do
        before do
          procedure.draft_revision.find_or_clone_type_de_champ(mandatory_type_de_champ.stable_id).update(mandatory: false)
          procedure.publish_revision!
          dossier.reload
        end

        it 'should be false' do
          expect(dossier.pending_changes).not_to be_empty
          expect(dossier.can_rebase?).to be_falsey
        end
      end
    end
  end

  describe "#rebase" do
    let(:procedure) { create(:procedure, :with_type_de_champ_mandatory, :with_yes_no, :with_repetition, :with_datetime) }
    let(:dossier) { create(:dossier, procedure: procedure) }

    let(:yes_no_type_de_champ) { procedure.types_de_champ.find { |tdc| tdc.type_champ == TypeDeChamp.type_champs.fetch(:yes_no) } }

    let(:text_type_de_champ) { procedure.types_de_champ.find(&:mandatory?) }
    let(:text_champ) { dossier.champs.find(&:mandatory?) }
    let(:rebased_text_champ) { dossier.champs.find { |c| c.type_champ == TypeDeChamp.type_champs.fetch(:text) } }

    let(:datetime_type_de_champ) { procedure.types_de_champ.find { |tdc| tdc.type_champ == TypeDeChamp.type_champs.fetch(:datetime) } }
    let(:datetime_champ) { dossier.champs.find { |c| c.type_champ == TypeDeChamp.type_champs.fetch(:datetime) } }
    let(:rebased_datetime_champ) { dossier.champs.find { |c| c.type_champ == TypeDeChamp.type_champs.fetch(:date) } }

    let(:repetition_type_de_champ) { procedure.types_de_champ.find { |tdc| tdc.type_champ == TypeDeChamp.type_champs.fetch(:repetition) } }
    let(:repetition_text_type_de_champ) { procedure.active_revision.children_of(repetition_type_de_champ).find { |tdc| tdc.type_champ == TypeDeChamp.type_champs.fetch(:text) } }
    let(:repetition_champ) { dossier.champs.find { |c| c.type_champ == TypeDeChamp.type_champs.fetch(:repetition) } }
    let(:rebased_repetition_champ) { dossier.champs.find { |c| c.type_champ == TypeDeChamp.type_champs.fetch(:repetition) } }

    before do
      procedure.publish!
      procedure.draft_revision.add_type_de_champ({
        type_champ: TypeDeChamp.type_champs.fetch(:text),
        libelle: "Un champ text"
      })
      procedure.draft_revision.find_or_clone_type_de_champ(text_type_de_champ).update(mandatory: false, libelle: "nouveau libelle")
      procedure.draft_revision.find_or_clone_type_de_champ(datetime_type_de_champ).update(type_champ: TypeDeChamp.type_champs.fetch(:date))
      procedure.draft_revision.find_or_clone_type_de_champ(repetition_text_type_de_champ).update(libelle: "nouveau libelle dans une repetition")
      procedure.draft_revision.add_type_de_champ({
        type_champ: TypeDeChamp.type_champs.fetch(:checkbox),
        libelle: "oui ou non",
        parent_id: repetition_type_de_champ.stable_id
      })
      procedure.draft_revision.remove_type_de_champ(yes_no_type_de_champ.stable_id)

      datetime_champ.update(value: Date.today.to_s)
      text_champ.update(value: 'bonjour')
      # Add two rows then remove previous to last row in order to create a "hole" in the sequence
      repetition_champ.add_row(repetition_champ.dossier.revision)
      repetition_champ.add_row(repetition_champ.dossier.revision)
      repetition_champ.champs.where(row: repetition_champ.champs.last.row - 1).destroy_all
      repetition_champ.reload
    end

    it "updates the brouillon champs with the latest revision changes" do
      revision_id = dossier.revision_id
      libelle = text_type_de_champ.libelle

      expect(dossier.revision).to eq(procedure.published_revision)
      expect(dossier.champs.size).to eq(4)
      expect(repetition_champ.rows.size).to eq(2)
      expect(repetition_champ.rows[0].size).to eq(1)
      expect(repetition_champ.rows[1].size).to eq(1)

      procedure.publish_revision!
      perform_enqueued_jobs
      procedure.reload
      dossier.reload

      expect(procedure.revisions.size).to eq(3)
      expect(dossier.revision).to eq(procedure.published_revision)
      expect(dossier.champs.size).to eq(4)
      expect(rebased_text_champ.value).to eq(text_champ.value)
      expect(rebased_text_champ.type_de_champ_id).not_to eq(text_champ.type_de_champ_id)
      expect(rebased_datetime_champ.type_champ).to eq(TypeDeChamp.type_champs.fetch(:date))
      expect(rebased_datetime_champ.value).to be_nil
      expect(rebased_repetition_champ.rows.size).to eq(2)
      expect(rebased_repetition_champ.rows[0].size).to eq(2)
      expect(rebased_repetition_champ.rows[1].size).to eq(2)
      expect(rebased_text_champ.rebased_at).not_to be_nil
      expect(rebased_datetime_champ.rebased_at).not_to be_nil
    end
  end

  context 'small grained' do
    subject do
      procedure.publish_revision!
      perform_enqueued_jobs

      dossier.reload
    end

    context 'with a procedure with a dropdown tdc' do
      let!(:procedure) do
        create(:procedure).tap do |p|
          p.draft_revision.add_type_de_champ(type_champ: :drop_down_list, libelle: 'l1', drop_down_list_value: 'option')
          p.publish!
        end
      end
      let!(:dossier) { create(:dossier, procedure: procedure) }

      context 'when a dropdown option is changed' do
        before do
          dossier.champs.first.update(value: 'v1')

          stable_id = procedure.draft_revision.types_de_champ.find_by(libelle: 'l1')
          tdc_to_update = procedure.draft_revision.find_or_clone_type_de_champ(stable_id)
          tdc_to_update.update(drop_down_list_value: 'option updated')
        end

        it { expect { subject }.to change { dossier.champs.first.value }.from('v1').to(nil) }
      end
    end

    context 'with a procedure with a carte tdc' do
      let!(:procedure) do
        create(:procedure).tap do |p|
          champ = p.draft_revision.add_type_de_champ(type_champ: :carte, libelle: 'l1', cadastres: true)
          p.publish!
        end
      end
      let!(:dossier) { create(:dossier, procedure: procedure) }

      context 'and the cadastre are removed' do
        before do
          dossier.champs.first.update(value: 'v1', geo_areas: [create(:geo_area, :cadastre)])

          stable_id = procedure.draft_revision.types_de_champ.find_by(libelle: 'l1')
          tdc_to_update = procedure.draft_revision.find_or_clone_type_de_champ(stable_id)
          tdc_to_update.update(cadastres: false)
        end

        it { expect { subject }.to change { dossier.champs.first.cadastres.count }.from(1).to(0) }
      end
    end

    context 'with a procedure with 2 tdc' do
      let!(:procedure) do
        create(:procedure).tap do |p|
          p.draft_revision.add_type_de_champ(type_champ: :text, libelle: 'l1')
          p.draft_revision.add_type_de_champ(type_champ: :text, libelle: 'l2')
          p.publish!
        end
      end
      let!(:dossier) { create(:dossier, procedure: procedure) }

      def champ_libelles = dossier.champs.map(&:libelle)

      context 'when a tdc is added in the middle' do
        before do
          added_tdc = procedure.draft_revision.add_type_de_champ(type_champ: :text, libelle: 'l3')
          procedure.draft_revision.move_type_de_champ(added_tdc.stable_id, 1)
        end

        it { expect { subject }.to change { champ_libelles }.from(['l1', 'l2']).to(['l1', 'l3', 'l2']) }
      end

      context 'when the first tdc is removed' do
        before do
          stable_id = procedure.draft_revision.types_de_champ.find_by(libelle: 'l1')
          tdc_to_remove = procedure.draft_revision.find_or_clone_type_de_champ(stable_id)
          procedure.draft_revision.remove_type_de_champ(tdc_to_remove.stable_id)
        end

        it { expect { subject }.to change { champ_libelles }.from(['l1', 'l2']).to(['l2']) }
      end

      context 'when the second tdc is moved at the first place' do
        before do
          stable_id = procedure.draft_revision.types_de_champ.find_by(libelle: 'l2')
          procedure.draft_revision.move_type_de_champ(stable_id, 0)
        end

        it { expect { subject }.to change { champ_libelles }.from(['l1', 'l2']).to(['l2', 'l1']) }
      end

      context 'when the first tdc libelle is updated' do
        before do
          stable_id = procedure.draft_revision.types_de_champ.find_by(libelle: 'l1')
          tdc_to_update = procedure.draft_revision.find_or_clone_type_de_champ(stable_id)
          tdc_to_update.update(libelle: 'l1 updated')
        end

        it { expect { subject }.to change { champ_libelles }.from(['l1', 'l2']).to(['l1 updated', 'l2']) }
      end

      context 'when the first tdc type is updated' do
        def first_champ = dossier.champs.first

        before do
          first_champ.update(value: 'v1', external_id: '123', geo_areas: [create(:geo_area)])
          first_champ.update(data: { a: 1 })

          first_champ.piece_justificative_file.attach(
            io: StringIO.new("toto"),
            filename: "toto.txt",
            content_type: "text/plain",
            # we don't want to run virus scanner on this file
            metadata: { virus_scan_result: ActiveStorage::VirusScanner::SAFE }
          )

          first_champ.update_column('updated_at', Time.zone.parse('01/01/1901'))

          stable_id = procedure.draft_revision.types_de_champ.find_by(libelle: 'l1')
          tdc_to_update = procedure.draft_revision.find_or_clone_type_de_champ(stable_id)
          tdc_to_update.update(type_champ: :integer_number)
        end

        it { expect { subject }.to change { dossier.champs.map(&:type_champ) }.from(['text', 'text']).to(['integer_number', 'text']) }
        it { expect { subject }.to change { first_champ.class }.from(Champs::TextChamp).to(Champs::IntegerNumberChamp) }
        it { expect { subject }.to change { first_champ.value }.from('v1').to(nil) }
        it { expect { subject }.to change { first_champ.external_id }.from('123').to(nil) }
        it { expect { subject }.to change { first_champ.data }.from({ 'a' => 1 }).to(nil) }
        it { expect { subject }.to change { first_champ.geo_areas.count }.from(1).to(0) }
        it { expect { subject }.to change { first_champ.piece_justificative_file.attached? }.from(true).to(false) }
        # pb with pj.purge_later
        xit { expect { subject }.not_to change { first_champ.updated_at }.from(Time.zone.parse('01/01/1901')) }
      end
    end

    context 'with a procedure with a repetition' do
      let!(:procedure) do
        create(:procedure).tap do |p|
          repetition = p.draft_revision.add_type_de_champ(type_champ: :repetition, libelle: 'p1', mandatory: true)
          p.draft_revision.add_type_de_champ(type_champ: :text, libelle: 'c1', parent_id: repetition.stable_id)
          p.draft_revision.add_type_de_champ(type_champ: :text, libelle: 'c2', parent_id: repetition.stable_id)
          p.publish!
        end
      end
      let!(:dossier) { create(:dossier, procedure: procedure) }
      let(:repetition_stable_id) { procedure.draft_revision.types_de_champ.find(&:repetition?) }

      def child_libelles = dossier.champs[0].champs.map(&:libelle)

      context 'when a child tdc is added in the middle' do
        before do
          added_tdc = procedure.draft_revision.add_type_de_champ(type_champ: :text, libelle: 'c3', parent_id: repetition_stable_id, mandatory: true)
          procedure.draft_revision.move_type_de_champ(added_tdc.stable_id, 1)
        end

        it { expect { subject }.to change { child_libelles }.from(['c1', 'c2']).to(['c1', 'c3', 'c2']) }
      end

      context 'when the first child tdc is removed' do
        before do
          tdc_to_remove = procedure.draft_revision.types_de_champ.find_by(libelle: 'c1')
          procedure.draft_revision.remove_type_de_champ(tdc_to_remove.stable_id)
        end

        it { expect { subject }.to change { child_libelles }.from(['c1', 'c2']).to(['c2']) }
      end

      context 'when the first child libelle tdc is updated' do
        before do
          stable_id = procedure.draft_revision.types_de_champ.find_by(libelle: 'c1')
          tdc_to_update = procedure.draft_revision.find_or_clone_type_de_champ(stable_id)
          tdc_to_update.update(libelle: 'c1 updated')
        end

        it { expect { subject }.to change { child_libelles }.from(['c1', 'c2']).to(['c1 updated', 'c2']) }
      end

      context 'when the first child tdc type is updated' do
        before do
          stable_id = procedure.draft_revision.types_de_champ.find_by(libelle: 'c1')
          tdc_to_update = procedure.draft_revision.find_or_clone_type_de_champ(stable_id)
          tdc_to_update.update(type_champ: :integer_number)
        end

        it { expect { subject }.to change { dossier.champs[0].champs.map(&:type_champ) }.from(['text', 'text']).to(['integer_number', 'text']) }
      end

      context 'when the parents type is changed' do
        before do
          stable_id = procedure.draft_revision.types_de_champ.find_by(libelle: 'p1')
          parent = procedure.draft_revision.find_or_clone_type_de_champ(stable_id)
          parent.update(type_champ: :integer_number)
        end

        it { expect { subject }.to change { dossier.champs[0].champs.count }.from(2).to(0) }
        it { expect { subject }.to change { Champ.count }.from(3).to(1) }
      end
    end
  end
end
