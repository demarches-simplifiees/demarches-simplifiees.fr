namespace :after_party do
  desc 'Deployment task: normalize_departements'
  task normalize_departements: :environment do
    puts "Running deploy task 'normalize_departements'"

    scope_85 = Champs::DepartementChamp.where(external_id: [nil, ''], value: "85")
    scope_external_id_nil = Champs::DepartementChamp.where(external_id: '', value: nil)
    scope_external_id_nil_value_empty = Champs::DepartementChamp.where(external_id: nil, value: '')
    scope_external_id_empty_value_empty = Champs::DepartementChamp.where(external_id: '', value: '')
    scope_value_blank = Champs::DepartementChamp.where(value: [nil, '']).where.not(external_id: [nil, ''])
    scope_external_id_blank = Champs::DepartementChamp.where(external_id: [nil, '']).where.not(value: [nil, ''])
    scope_value_old_format = Champs::DepartementChamp.where.not(external_id: [nil, '']).where("value ~ ?", '^(\w{2,3}) - (.+)')

    progress = ProgressReport.new(
      scope_85.count +
      scope_external_id_nil.count +
      scope_external_id_nil_value_empty.count +
      scope_external_id_empty_value_empty.count +
      scope_value_blank.count +
      scope_external_id_blank.count +
      scope_value_old_format.count
    )

    update_all(scope_85, progress, value: "Vendée")

    update_all(scope_external_id_nil, progress, external_id: nil)

    update_all(scope_external_id_nil_value_empty, progress, value: nil)

    update_all(scope_external_id_empty_value_empty, progress, external_id: nil, value: nil)

    scope_value_blank.find_each do |champ|
      champ.update_columns(value: APIGeoService.departement_name(champ.external_id))
      progress.inc
    end

    scope_external_id_blank.find_each do |champ|
      match = champ.value.match(/^(\w{2,3}) - (.+)/)
      if match
        code = match[1]
        name = APIGeoService.departement_name(code)
        champ.update_columns(external_id: code, value: name)
      else
        champ.update_columns(external_id: APIGeoService.departement_code(champ.value))
      end
      progress.inc
    end

    scope_value_old_format.find_each do |champ|
      code = champ.value.match(/^(\w{2,3}) - (.+)/)[1]
      name = APIGeoService.departement_name(code)
      champ.update_columns(external_id: code, value: name)

      progress.inc
    end

    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end

  private

  def update_all(scope, progress, attributes)
    scope.in_batches(of: 10_000) do |departements|
      progress.inc(departements.count)
      departements.update_all(attributes)
    end
  end
end
