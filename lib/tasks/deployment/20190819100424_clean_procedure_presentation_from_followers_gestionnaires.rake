namespace :after_party do
  desc 'Deployment task: clean_procedure_presentation_from_followers_gestionnaires'
  task clean_procedure_presentation_from_followers_gestionnaires: :environment do
    ProcedurePresentation.find_each do |pp|
      if pp.sort["table"] == "followers_gestionnaires"
        pp.sort["table"] = "followers_instructeurs"
      end

      pp.displayed_fields.each do |df|
        if df["table"] == "followers_gestionnaires"
          df["table"] = "followers_instructeurs"
        end
      end

      pp.filters.each do |(_name, values)|
        values.each do |value|
          if value["table"] == "followers_gestionnaires"
            value["table"] = "followers_instructeurs"
          end
        end
      end

      begin
        pp.save!
      rescue ActiveRecord::RecordInvalid
      end
    end
    AfterParty::TaskRecord.create version: '20190819100424'
  end
end
