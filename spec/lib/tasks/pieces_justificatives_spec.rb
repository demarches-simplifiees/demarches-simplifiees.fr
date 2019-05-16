describe 'pieces_justificatives' do
  describe 'migrate_procedure_to_champs' do
    let(:rake_task) { Rake::Task['pieces_justificatives:migrate_procedure_to_champs'] }
    let(:procedure) { create(:procedure, :with_two_type_de_piece_justificative) }

    before do
      ENV['PROCEDURE_ID'] = procedure.id.to_s

      allow_any_instance_of(PieceJustificativeToChampPieceJointeMigrationService).to receive(:ensure_correct_storage_configuration!)

      rake_task.invoke
    end

    after { rake_task.reenable }

    it 'migrates the procedure' do
      expect(procedure.reload.types_de_piece_justificative).to be_empty
    end
  end

  describe 'migrate_procedures_range_to_champs' do
    let(:rake_task) { Rake::Task['pieces_justificatives:migrate_procedures_range_to_champs'] }
    let(:procedure_in_range_1) { create(:procedure, :with_two_type_de_piece_justificative) }
    let(:procedure_in_range_2) { create(:procedure, :with_two_type_de_piece_justificative) }
    let(:procedure_out_of_range) { create(:procedure, :with_two_type_de_piece_justificative) }

    before do
      procedure_in_range_1
      procedure_in_range_2
      procedure_out_of_range

      ENV['RANGE_START'] = procedure_in_range_1.id.to_s
      ENV['RANGE_END'] = procedure_in_range_2.id.to_s

      allow_any_instance_of(PieceJustificativeToChampPieceJointeMigrationService).to receive(:ensure_correct_storage_configuration!)

      rake_task.invoke
    end

    after { rake_task.reenable }

    it 'migrates procedures in the ids range' do
      expect(procedure_in_range_1.reload.types_de_piece_justificative).to be_empty
      expect(procedure_in_range_2.reload.types_de_piece_justificative).to be_empty
    end

    it 'doesn’t migrate procedures not in the range' do
      expect(procedure_out_of_range.reload.types_de_piece_justificative).to be_present
    end
  end
end
