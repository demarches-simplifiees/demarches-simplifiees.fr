namespace :'2017_09_21_add_procedure_presentations' do
  task set: :environment do
    AssignTo.all.each do |at|
      ProcedurePresentation.create(assign_to_id: at.id)
    end
  end
end
