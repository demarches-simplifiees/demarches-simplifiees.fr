describe DossierRebaseConcern do
  describe '#can_rebase?' do
    let(:procedure) { create(:procedure, types_de_champ_public: [{ mandatory: true }, { type: :yes_no }], types_de_champ_private: [{}]) }
    let(:attestation_template) { procedure.draft_revision.attestation_template.find_or_revise! }
    let(:type_de_champ) { procedure.active_revision.types_de_champ_public.find { |tdc| !tdc.mandatory? } }
    let(:private_type_de_champ) { procedure.active_revision.types_de_champ_private.first }
    let(:mandatory_type_de_champ) { procedure.active_revision.types_de_champ_public.find(&:mandatory?) }

    context 'on unpublished procedure' do
      context 'en_construction' do
        let(:dossier) { create(:dossier, :en_construction, procedure: procedure) }

        it 'should be false' do
          expect(dossier.pending_changes).to be_empty
          expect(dossier.can_rebase?).to be_falsey
        end
      end
    end

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

        it 'should be true' do
          expect(dossier.pending_changes).not_to be_empty
          expect(dossier.can_rebase?).to be_truthy
        end
      end

      context 'with added mandatory type de champ' do
        before do
          procedure.draft_revision.add_type_de_champ({
            type_champ: TypeDeChamp.type_champs.fetch(:text),
            libelle: "Un champ text",
            mandatory: true
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
          procedure.draft_revision.find_and_ensure_exclusive_use(mandatory_type_de_champ.stable_id).update(mandatory: false)
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
          procedure.draft_revision.find_and_ensure_exclusive_use(type_de_champ.stable_id).update(mandatory: true)
          procedure.publish_revision!
          dossier.reload
        end

        it 'should be false' do
          expect(dossier.pending_changes).not_to be_empty
          expect(dossier.can_rebase?).to be_falsey
        end

        context 'with a value' do
          before do
            dossier.champs.find_by(type_de_champ: type_de_champ).update(value: 'a value')
          end

          it 'should be true' do
            expect(dossier.pending_changes).not_to be_empty
            expect(dossier.can_rebase?).to be_truthy
          end
        end
      end

      context 'with type de champ change type' do
        context 'type de champ public' do
          before do
            procedure.draft_revision.find_and_ensure_exclusive_use(type_de_champ.stable_id).update(type_champ: :checkbox)
            procedure.publish_revision!
            dossier.reload
          end

          it 'should be false' do
            expect(dossier.pending_changes).not_to be_empty
            expect(dossier.can_rebase?).to be_falsey
          end
        end

        context 'type de champ private' do
          before do
            procedure.draft_revision.find_and_ensure_exclusive_use(private_type_de_champ.stable_id).update(type_champ: :checkbox)
            procedure.publish_revision!
            dossier.reload
          end

          it 'should be true' do
            expect(dossier.pending_changes).not_to be_empty
            expect(dossier.can_rebase?).to be_truthy
          end
        end
      end

      context 'with type de champ regexp and regexp change' do
        let(:procedure) { create(:procedure, types_de_champ_public: [{ mandatory: true }, { type: :expression_reguliere }], types_de_champ_private: [{}]) }

        before do
          procedure.draft_revision.find_and_ensure_exclusive_use(type_de_champ.stable_id).update(expression_reguliere: /\d+/)
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

        it 'should be true' do
          expect(dossier.pending_changes).not_to be_empty
          expect(dossier.can_rebase?).to be_truthy
        end
      end

      context 'with added mandatory type de champ' do
        before do
          procedure.draft_revision.add_type_de_champ({
            type_champ: TypeDeChamp.type_champs.fetch(:text),
            libelle: "Un champ text",
            mandatory: true
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
          procedure.draft_revision.find_and_ensure_exclusive_use(mandatory_type_de_champ.stable_id).update(mandatory: false)
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
          procedure.draft_revision.find_and_ensure_exclusive_use(type_de_champ.stable_id).update(mandatory: true)
          procedure.publish_revision!
          dossier.reload
        end

        it 'should be false' do
          expect(dossier.pending_changes).not_to be_empty
          expect(dossier.can_rebase?).to be_falsey
        end
      end

      context 'with type de champ change type' do
        context 'type de champ public' do
          before do
            procedure.draft_revision.find_and_ensure_exclusive_use(type_de_champ.stable_id).update(type_champ: :checkbox)
            procedure.publish_revision!
            dossier.reload
          end

          it 'should be false' do
            expect(dossier.pending_changes).not_to be_empty
            expect(dossier.can_rebase?).to be_falsey
          end
        end

        context 'type de champ private' do
          before do
            procedure.draft_revision.find_and_ensure_exclusive_use(private_type_de_champ.stable_id).update(type_champ: :checkbox)
            procedure.publish_revision!
            dossier.reload
          end

          it 'should be true' do
            expect(dossier.pending_changes).not_to be_empty
            expect(dossier.can_rebase?).to be_truthy
          end
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
    end
  end

  describe "#rebase" do
    let(:procedure) { create(:procedure, types_de_champ_public:, types_de_champ_private:) }
    let(:types_de_champ_public) do
      [
        { type: :text, mandatory: true, stable_id: 1 },
        {
          type: :repetition, stable_id: 101, mandatory: true, children: [
            { type: :text, stable_id: 102 }
          ]
        },
        { type: :datetime, stable_id: 103 },
        { type: :yes_no, stable_id: 104 },
        { type: :integer_number, stable_id: 105 }
      ]
    end
    let(:types_de_champ_private) { [{ type: :text, stable_id: 11 }] }
    let(:dossier) { create(:dossier, :with_entreprise, procedure: procedure) }
    let(:types_de_champ) { procedure.active_revision.types_de_champ }

    let(:text_type_de_champ) { types_de_champ.find { _1.stable_id == 1 } }
    let(:repetition_type_de_champ) { types_de_champ.find { _1.stable_id == 101 } }
    let(:repetition_text_type_de_champ) { types_de_champ.find { _1.stable_id == 102 } }
    let(:datetime_type_de_champ) { types_de_champ.find { _1.stable_id == 103 } }
    let(:yes_no_type_de_champ) { types_de_champ.find { _1.stable_id == 104 } }

    let(:text_champ) { dossier.champs_public.find { _1.stable_id == 1 } }
    let(:repetition_champ) { dossier.champs_public.find { _1.stable_id == 101 } }
    let(:datetime_champ) { dossier.champs_public.find { _1.stable_id == 103 } }

    let(:rebased_text_champ) { dossier.champs_public.find { _1.stable_id == 1 } }
    let(:rebased_repetition_champ) { dossier.champs_public.find { _1.stable_id == 101 } }
    let(:rebased_datetime_champ) { dossier.champs_public.find { _1.stable_id == 103 } }
    let(:rebased_number_champ) { dossier.champs_public.find { _1.stable_id == 105 } }

    let(:rebased_new_repetition_champ) { dossier.champs_public.find { _1.libelle == "une autre repetition" } }

    let(:private_text_type_de_champ) { types_de_champ.find { _1.stable_id == 11 } }
    let(:rebased_private_text_champ) { dossier.champs_private.find { _1.stable_id == 11 } }

    context "when revision is published" do
      before do
        procedure.publish!
        procedure.draft_revision.add_type_de_champ({
          type_champ: TypeDeChamp.type_champs.fetch(:text),
          libelle: "Un champ text"
        })
        procedure.draft_revision.find_and_ensure_exclusive_use(text_type_de_champ.stable_id).update(mandatory: false, libelle: "nouveau libelle")
        procedure.draft_revision.find_and_ensure_exclusive_use(datetime_type_de_champ.stable_id).update(type_champ: TypeDeChamp.type_champs.fetch(:date))
        procedure.draft_revision.find_and_ensure_exclusive_use(repetition_text_type_de_champ.stable_id).update(libelle: "nouveau libelle dans une repetition")
        procedure.draft_revision.add_type_de_champ({
          type_champ: TypeDeChamp.type_champs.fetch(:checkbox),
          libelle: "oui ou non",
          parent_stable_id: repetition_type_de_champ.stable_id
        })
        procedure.draft_revision.remove_type_de_champ(yes_no_type_de_champ.stable_id)
        new_repetition_type_de_champ = procedure.draft_revision.add_type_de_champ({
          type_champ: TypeDeChamp.type_champs.fetch(:repetition),
          libelle: "une autre repetition",
          mandatory: true
        })
        procedure.draft_revision.add_type_de_champ({
          type_champ: TypeDeChamp.type_champs.fetch(:text),
          libelle: "un champ text dans une autre repetition",
          parent_stable_id: new_repetition_type_de_champ.stable_id
        })
        procedure.draft_revision.add_type_de_champ({
          type_champ: TypeDeChamp.type_champs.fetch(:date),
          libelle: "un champ date dans une autre repetition",
          parent_stable_id: new_repetition_type_de_champ.stable_id
        })

        datetime_champ.update(value: Time.zone.now.to_s)
        text_champ.update(value: 'bonjour')
        # Add two rows then remove previous to last row in order to create a "hole" in the sequence
        repetition_champ.add_row(repetition_champ.dossier.revision)
        repetition_champ.add_row(repetition_champ.dossier.revision)
        repetition_champ.champs.where(row_id: repetition_champ.rows[-2].first.row_id).destroy_all
        repetition_champ.reload
      end

      it "updates the brouillon champs with the latest revision changes" do
        expect(dossier.revision).to eq(procedure.published_revision)
        expect(dossier.champs_public.size).to eq(5)
        expect(dossier.champs_public_all.size).to eq(7)
        expect(repetition_champ.rows.size).to eq(2)
        expect(repetition_champ.rows[0].size).to eq(1)
        expect(repetition_champ.rows[1].size).to eq(1)

        procedure.publish_revision!
        perform_enqueued_jobs
        procedure.reload
        dossier.reload

        expect(procedure.revisions.size).to eq(3)
        expect(dossier.revision).to eq(procedure.published_revision)
        expect(dossier.champs_public.size).to eq(6)
        expect(dossier.champs_public_all.size).to eq(12)
        expect(rebased_text_champ.value).to eq(text_champ.value)
        expect(rebased_text_champ.type_de_champ_id).not_to eq(text_champ.type_de_champ_id)
        expect(rebased_datetime_champ.type_champ).to eq(TypeDeChamp.type_champs.fetch(:date))
        expect(rebased_datetime_champ.value).to be_nil
        expect(rebased_repetition_champ.rows.size).to eq(2)
        expect(rebased_repetition_champ.rows[0].size).to eq(2)
        expect(rebased_repetition_champ.rows[1].size).to eq(2)
        expect(rebased_text_champ.rebased_at).not_to be_nil
        expect(rebased_datetime_champ.rebased_at).not_to be_nil
        expect(rebased_number_champ.rebased_at).to be_nil
        expect(rebased_new_repetition_champ).not_to be_nil
        expect(rebased_new_repetition_champ.rebased_at).not_to be_nil
        expect(rebased_new_repetition_champ.rows.size).to eq(1)
        expect(rebased_new_repetition_champ.rows[0].size).to eq(2)

        dossier.passer_en_construction!
        procedure.draft_revision.find_and_ensure_exclusive_use(private_text_type_de_champ.stable_id).update(type_champ: TypeDeChamp.type_champs.fetch(:textarea))
        procedure.publish_revision!
        perform_enqueued_jobs
        procedure.reload
        dossier.reload

        expect(rebased_private_text_champ.type_champ).to eq(TypeDeChamp.type_champs.fetch(:textarea))
        expect(rebased_private_text_champ.type).to eq("Champs::TextareaChamp")
      end
    end

    context 'force rebase en construction' do
      subject { dossier.rebase!(force: true) }

      context 'procedure not published' do
        let(:procedure) { create(:procedure, :draft, types_de_champ_public:, types_de_champ_private:) }
        let(:dossier) { create(:dossier, :en_construction, procedure:) }

        it 'is noop' do
          expect { subject }.not_to change { dossier.reload.champs_public[0].rebased_at }
          expect { subject }.not_to change { dossier.updated_at }
        end
      end
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
          p.draft_revision.add_type_de_champ(type_champ: :drop_down_list, libelle: 'l1', drop_down_list_value: "option\nv1\n")
          p.publish!
        end
      end
      let!(:dossier) { create(:dossier, procedure: procedure) }

      context 'when a dropdown option is added' do
        before do
          dossier.champs_public.first.update(value: 'v1')

          stable_id = procedure.draft_revision.types_de_champ.find_by(libelle: 'l1')
          tdc_to_update = procedure.draft_revision.find_and_ensure_exclusive_use(stable_id)
          tdc_to_update.update(drop_down_list_value: "option\nupdated\nv1")
        end

        it { expect { subject }.not_to change { dossier.champs_public.first.value } }
      end

      context 'when a dropdown option is removed' do
        before do
          dossier.champs_public.first.update(value: 'v1')

          stable_id = procedure.draft_revision.types_de_champ.find_by(libelle: 'l1')
          tdc_to_update = procedure.draft_revision.find_and_ensure_exclusive_use(stable_id)
          tdc_to_update.update(drop_down_list_value: "option\nupdated")
        end

        it { expect { subject }.to change { dossier.champs_public.first.value }.from('v1').to(nil) }
      end

      context 'when a dropdown unused option is removed' do
        before do
          dossier.champs_public.first.update(value: 'v1')

          stable_id = procedure.draft_revision.types_de_champ.find_by(libelle: 'l1')
          tdc_to_update = procedure.draft_revision.find_and_ensure_exclusive_use(stable_id)
          tdc_to_update.update(drop_down_list_value: "v1\nupdated")
        end

        it { expect { subject }.not_to change { dossier.champs_public.first.value } }
      end
    end

    context 'with a procedure with a multiple dropdown tdc' do
      let!(:procedure) do
        create(:procedure).tap do |p|
          p.draft_revision.add_type_de_champ(type_champ: :multiple_drop_down_list, libelle: 'l1', drop_down_list_value: "option\nv1\n")
          p.publish!
        end
      end
      let!(:dossier) { create(:dossier, procedure: procedure) }

      context 'when a dropdown option is added' do
        before do
          dossier.champs_public.first.update(value: '["v1"]')

          stable_id = procedure.draft_revision.types_de_champ.find_by(libelle: 'l1')
          tdc_to_update = procedure.draft_revision.find_and_ensure_exclusive_use(stable_id)
          tdc_to_update.update(drop_down_list_value: "option\nupdated\nv1")
        end

        it { expect { subject }.not_to change { dossier.champs_public.first.value } }
      end

      context 'when a dropdown option is removed' do
        before do
          dossier.champs_public.first.update(value: '["v1", "option"]')

          stable_id = procedure.draft_revision.types_de_champ.find_by(libelle: 'l1')
          tdc_to_update = procedure.draft_revision.find_and_ensure_exclusive_use(stable_id)
          tdc_to_update.update(drop_down_list_value: "option\nupdated")
        end

        it { expect { subject }.to change { dossier.champs_public.first.value }.from('["v1","option"]').to('["option"]') }
      end

      context 'when a dropdown unused option is removed' do
        before do
          dossier.champs_public.first.update(value: '["v1"]')

          stable_id = procedure.draft_revision.types_de_champ.find_by(libelle: 'l1')
          tdc_to_update = procedure.draft_revision.find_and_ensure_exclusive_use(stable_id)
          tdc_to_update.update(drop_down_list_value: "v1\nupdated")
        end

        it { expect { subject }.not_to change { dossier.champs_public.first.value } }
      end
    end

    context 'with a procedure with a linked dropdown tdc' do
      let!(:procedure) do
        create(:procedure).tap do |p|
          p.draft_revision.add_type_de_champ(type_champ: :linked_drop_down_list, libelle: 'l1', drop_down_list_value: "--titre1--\noption\nv1\n--titre2--\noption2\nv2\n")
          p.publish!
        end
      end
      let!(:dossier) { create(:dossier, procedure: procedure) }

      context 'when a dropdown option is added' do
        before do
          dossier.champs_public.first.update(value: '["v1",""]')

          stable_id = procedure.draft_revision.types_de_champ.find_by(libelle: 'l1')
          tdc_to_update = procedure.draft_revision.find_and_ensure_exclusive_use(stable_id)
          tdc_to_update.update(drop_down_list_value: "--titre1--\noption\nv1\nupdated\n--titre2--\noption2\nv2\n")
        end

        it { expect { subject }.not_to change { dossier.champs_public.first.value } }
      end

      context 'when a dropdown option is removed' do
        before do
          dossier.champs_public.first.update(value: '["v1","option2"]')

          stable_id = procedure.draft_revision.types_de_champ.find_by(libelle: 'l1')
          tdc_to_update = procedure.draft_revision.find_and_ensure_exclusive_use(stable_id)
          tdc_to_update.update(drop_down_list_value: "--titre1--\noption\nupdated\n--titre2--\noption2\nv2\n")
        end

        it { expect { subject }.to change { dossier.champs_public.first.value }.from('["v1","option2"]').to(nil) }
      end

      context 'when a dropdown unused option is removed' do
        before do
          dossier.champs_public.first.update(value: '["v1",""]')

          stable_id = procedure.draft_revision.types_de_champ.find_by(libelle: 'l1')
          tdc_to_update = procedure.draft_revision.find_and_ensure_exclusive_use(stable_id)
          tdc_to_update.update(drop_down_list_value: "--titre1--\nv1\nupdated\n--titre2--\noption2\nv2\n")
        end

        it { expect { subject }.not_to change { dossier.champs_public.first.value } }
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
          dossier.champs_public.first.update(value: 'v1', geo_areas: [create(:geo_area, :cadastre)])

          stable_id = procedure.draft_revision.types_de_champ.find_by(libelle: 'l1')
          tdc_to_update = procedure.draft_revision.find_and_ensure_exclusive_use(stable_id)
          tdc_to_update.update(cadastres: false)
        end

        it { expect { subject }.to change { dossier.champs_public.first.cadastres.count }.from(1).to(0) }
      end
    end

    context 'with a procedure with 2 tdc' do
      let!(:procedure) do
        create(:procedure, :published, types_de_champ_public: [{ type: :text, libelle: 'l1' }, { type: :text, libelle: 'l2' }])
      end
      let!(:dossier) { create(:dossier, procedure: procedure) }

      def champ_libelles = dossier.revision.types_de_champ_public.map(&:libelle)

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
          tdc_to_remove = procedure.draft_revision.find_and_ensure_exclusive_use(stable_id)
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
          tdc_to_update = procedure.draft_revision.find_and_ensure_exclusive_use(stable_id)
          tdc_to_update.update(libelle: 'l1 updated')
        end

        it { expect { subject }.to change { champ_libelles }.from(['l1', 'l2']).to(['l1 updated', 'l2']) }
      end

      context 'when the first tdc type is updated' do
        def first_champ = dossier.champs_public.first

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
          tdc_to_update = procedure.draft_revision.find_and_ensure_exclusive_use(stable_id)
          tdc_to_update.update(type_champ: :integer_number)
        end

        it { expect { subject }.to change { dossier.revision.types_de_champ_public.map(&:type_champ) }.from(['text', 'text']).to(['integer_number', 'text']) }
        it { expect { subject }.to change { first_champ.class }.from(Champs::TextChamp).to(Champs::IntegerNumberChamp) }
        it { expect { subject }.to change { first_champ.value }.from('v1').to(nil) }
        it { expect { subject }.to change { first_champ.external_id }.from('123').to(nil) }
        it { expect { subject }.to change { first_champ.data }.from({ 'a' => 1 }).to(nil) }
        it { expect { subject }.to change { first_champ.geo_areas.count }.from(1).to(0) }
        it { expect { subject }.to change { first_champ.piece_justificative_file.attached? }.from(true).to(false) }
        it { expect { subject }.not_to change { first_champ.updated_at }.from(Time.zone.parse('01/01/1901')) }
      end
    end

    context 'with a procedure with a repetition' do
      let!(:procedure) do
        create(:procedure, :published, types_de_champ_public: [
          {
            type: :repetition,
            libelle: 'p1',
            mandatory: true,
            children: [
              { type: :text, libelle: 'c1' },
              { type: :text, libelle: 'c2' }
            ]
          }
        ])
      end
      let!(:dossier) { create(:dossier, procedure: procedure) }
      let(:repetition) { procedure.draft_revision.types_de_champ.find(&:repetition?) }

      def child_libelles = dossier.revision.revision_types_de_champ_public.first.revision_types_de_champ.map(&:libelle)
      def child_types_champ = dossier.revision.revision_types_de_champ_public.first.revision_types_de_champ.map(&:type_champ)

      context 'when a child tdc is added in the middle' do
        before do
          last_child = procedure.draft_revision.children_of(repetition).last
          added_tdc = procedure.draft_revision.add_type_de_champ(type_champ: :text, libelle: 'c3', parent_stable_id: repetition.stable_id, after_stable_id: last_child)
          procedure.draft_revision.move_type_de_champ(added_tdc.stable_id, 1)
          # procedure.publish_revision!
        end

        it 'does somehting' do
          expect { subject }.to change { child_libelles }.from(['c1', 'c2']).to(['c1', 'c3', 'c2'])
        end
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
          tdc_to_update = procedure.draft_revision.find_and_ensure_exclusive_use(stable_id)
          tdc_to_update.update(libelle: 'c1 updated')
        end

        it { expect { subject }.to change { child_libelles }.from(['c1', 'c2']).to(['c1 updated', 'c2']) }
      end

      context 'when the first child tdc type is updated' do
        before do
          stable_id = procedure.draft_revision.types_de_champ.find_by(libelle: 'c1')
          tdc_to_update = procedure.draft_revision.find_and_ensure_exclusive_use(stable_id)
          tdc_to_update.update(type_champ: :integer_number)
        end

        it { expect { subject }.to change { child_types_champ }.from(['text', 'text']).to(['integer_number', 'text']) }
      end

      context 'when the parents type is changed' do
        before do
          stable_id = procedure.draft_revision.types_de_champ.find_by(libelle: 'p1')
          parent = procedure.draft_revision.find_and_ensure_exclusive_use(stable_id)
          parent.update(type_champ: :integer_number)
        end

        it { expect { subject }.to change { dossier.champs_public.first.champs.count }.from(2).to(0) }
        it { expect { subject }.to change { Champ.count }.from(3).to(1) }
      end
    end
  end
end
