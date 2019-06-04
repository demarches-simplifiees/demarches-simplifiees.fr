require 'spec_helper'

describe PieceJustificativeToChampPieceJointeMigrationService do
  let(:service) { PieceJustificativeToChampPieceJointeMigrationService.new(storage_service: storage_service) }
  let(:storage_service) { CarrierwaveActiveStorageMigrationService.new }
  let(:pj_uploader) { class_double(PieceJustificativeUploader) }
  let(:pj_service) { class_double(PiecesJustificativesService) }

  let(:procedure) { create(:procedure, types_de_piece_justificative: types_pj) }
  let(:types_pj) { [create(:type_de_piece_justificative)] }

  let!(:dossier) { make_dossier }

  let(:pjs) { [] }

  def make_dossier(hidden: false)
    create(:dossier,
      procedure: procedure,
      pieces_justificatives: pjs,
      hidden_at: hidden ? Time.zone.now : nil)
  end

  def make_pjs
    types_pj.map do |tpj|
      create(:piece_justificative, :contrat, type_de_piece_justificative: tpj)
    end
  end

  def expect_storage_service_to_convert_object
    expect(storage_service).to receive(:make_blob)
    expect(storage_service).to receive(:copy_from_carrierwave_to_active_storage!)
    expect(storage_service).to receive(:make_attachment)
  end

  describe '.number_of_champs_to_migrate' do
    let!(:other_dossier) { make_dossier }

    it 'reports the numbers of champs to be migrated' do
      expect(service.number_of_champs_to_migrate(procedure)).to eq(4)
    end

    context 'when the procedure has hidden dossiers' do
      let!(:hidden_dossier) { make_dossier(hidden: true) }

      it 'reports the numbers of champs including those of hidden dossiers' do
        expect(service.number_of_champs_to_migrate(procedure)).to eq(6)
      end
    end
  end

  context 'when conversion succeeds' do
    context 'for the procedure' do
      it 'types de champ are created for the "pièces jointes" header and for each PJ' do
        expect { service.convert_procedure_pjs_to_champ_pjs(procedure) }
          .to change { procedure.types_de_champ.count }
          .by(types_pj.count + 1)
      end

      it 'the old types de pj are removed' do
        expect { service.convert_procedure_pjs_to_champ_pjs(procedure) }
          .to change { procedure.types_de_piece_justificative.count }
          .to(0)
      end
    end

    context 'no notifications are sent to instructeurs' do
      context 'when there is a PJ' do
        let(:pjs) { make_pjs }

        before do
          # Reload PJ because the resolution of in-database timestamps is
          # different from the resolution of in-memory timestamps, causing the
          # tests to fail on fractional time differences.
          pjs.last.reload

          expect_storage_service_to_convert_object
          Timecop.travel(1.hour) { service.convert_procedure_pjs_to_champ_pjs(procedure) }

          # Reload the dossier to see the newly created champs
          dossier.reload
        end

        it 'the champ has the same created_at as the PJ' do
          expect(dossier.champs.last.created_at).to eq(pjs.last.created_at)
        end

        it 'the champ has the same updated_at as the PJ' do
          expect(dossier.champs.last.updated_at).to eq(pjs.last.updated_at)
        end
      end

      context 'when there is no PJ' do
        let!(:expected_updated_at) do
          # Reload dossier because the resolution of in-database timestamps is
          # different from the resolution of in-memory timestamps, causing the
          # tests to fail on fractional time differences.
          dossier.reload
          dossier.updated_at
        end

        before do
          Timecop.travel(1.hour) { service.convert_procedure_pjs_to_champ_pjs(procedure) }

          # Reload the dossier to see the newly created champs
          dossier.reload
        end

        it 'the champ has the same created_at as the dossier' do
          expect(dossier.champs.last.created_at).to eq(dossier.created_at)
        end

        it 'the champ has the same updated_at as the dossier' do
          expect(dossier.champs.last.updated_at).to eq(expected_updated_at)
        end
      end
    end

    context 'for the dossier' do
      let(:pjs) { make_pjs }

      before { expect_storage_service_to_convert_object }

      it 'champs are created for the "pièces jointes" header and for each PJ' do
        expect { service.convert_procedure_pjs_to_champ_pjs(procedure) }
          .to change { dossier.champs.count }
          .by(types_pj.count + 1)
      end

      it 'the old pjs are removed' do
        expect { service.convert_procedure_pjs_to_champ_pjs(procedure) }
          .to change { dossier.pieces_justificatives.count }
          .to(0)
      end

      context 'when the procedure has several dossiers' do
        let!(:other_dossier) { make_dossier }

        it 'sends progress callback for each migrated champ' do
          number_of_champs_to_migrate = service.number_of_champs_to_migrate(procedure)

          progress_count = 0
          service.convert_procedure_pjs_to_champ_pjs(procedure) do
            progress_count += 1
          end

          expect(progress_count).to eq(number_of_champs_to_migrate)
        end
      end
    end

    context 'when the dossier is soft-deleted it still gets converted' do
      let(:pjs) { make_pjs }
      let!(:dossier) { make_dossier(hidden: true) }

      before { expect_storage_service_to_convert_object }

      it 'champs are created for the "pièces jointes" header and for each PJ' do
        expect { service.convert_procedure_pjs_to_champ_pjs(procedure) }
          .to change { dossier.champs.count }
          .by(types_pj.count + 1)
      end

      it 'the old pjs are removed' do
        expect { service.convert_procedure_pjs_to_champ_pjs(procedure) }
          .to change { dossier.pieces_justificatives.count }
          .to(0)
      end
    end

    context 'when there are several pjs for one type' do
      let(:pjs) { make_pjs + make_pjs }

      it 'only converts the most recent PJ for each type PJ' do
        expect(storage_service).to receive(:make_blob).exactly(types_pj.count)
        expect(storage_service).to receive(:copy_from_carrierwave_to_active_storage!).exactly(types_pj.count)
        expect(storage_service).to receive(:make_attachment).exactly(types_pj.count)

        service.convert_procedure_pjs_to_champ_pjs(procedure)
      end
    end
  end

  context 'cleanup when conversion fails' do
    let(:pjs) { make_pjs }
    let(:exception) { 'LOL no!' }

    let!(:failing_dossier) do
      create(
        :dossier,
        procedure: procedure,
        pieces_justificatives: make_pjs
      )
    end

    before do
      allow(storage_service).to receive(:checksum).and_return('cafe')
      allow(storage_service).to receive(:fix_content_type)

      expect(storage_service).to receive(:copy_from_carrierwave_to_active_storage!)
      expect(storage_service).to receive(:copy_from_carrierwave_to_active_storage!)
        .and_raise(exception)

      expect(storage_service).to receive(:delete_from_active_storage!)
    end

    def try_convert(procedure)
      service.convert_procedure_pjs_to_champ_pjs(procedure)
    rescue StandardError, SignalException => e
      e
    end

    it 'passes on the exception' do
      expect { service.convert_procedure_pjs_to_champ_pjs(procedure) }
        .to raise_error('LOL no!')
    end

    it 'does not create champs' do
      expect { try_convert(procedure) }
        .not_to change { dossier.champs.count }
    end

    it 'does not remove any old pjs' do
      expect { try_convert(procedure) }
        .not_to change { dossier.pieces_justificatives.count }
    end

    it 'does not creates types de champ' do
      expect { try_convert(procedure) }
        .not_to change { procedure.types_de_champ.count }
    end

    it 'does not remove old types de pj' do
      expect { try_convert(procedure) }
        .not_to change { procedure.types_de_piece_justificative.count }
    end

    it 'does not leave stale blobs behind' do
      expect { try_convert(procedure) }
        .not_to change { ActiveStorage::Blob.count }
    end

    it 'does not leave stale attachments behind' do
      expect { try_convert(procedure) }
        .not_to change { ActiveStorage::Attachment.count }
    end

    context 'when receiving a Signal interruption (like Ctrl+C)' do
      let(:exception) { Interrupt }

      it 'handles the exception as well' do
        expect { service.convert_procedure_pjs_to_champ_pjs(procedure) }.to raise_error { Interrupt }
      end

      it 'does not create champs' do
        expect { try_convert(procedure) }.not_to change { dossier.champs.count }
      end
    end
  end
end
