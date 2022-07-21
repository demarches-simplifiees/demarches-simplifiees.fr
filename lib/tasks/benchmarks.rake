namespace :benchmarks do
  desc 'Benchmark exports'
  task exports: :environment do
    p_45964 = Procedure.find(45964)
    p_55824 = Procedure.find(55824)
    Benchmark.bm do |x|
      x.report("Démarche 45964") { ProcedureExportService.new(p_45964, p_45964.dossiers).to_xlsx }
      x.report("Démarche 55824") { ProcedureExportService.new(p_55824, p_55824.dossiers).to_xlsx }
    end
  end

  desc 'Benchmark graphql'
  task graphql: :environment do
    p_45964 = Procedure.find(45964)
    p_55824 = Procedure.find(55824)
    Benchmark.bm do |x|
      x.report("Démarche 45964") { SerializerService.dossiers(p_45964) }
      x.report("Démarche 55824") { SerializerService.dossiers(p_55824) }
      x.report("Démarches publiques") { SerializerService.demarches_publiques }
    end
  end

  desc 'Benchmark pdf'
  task pdf: :environment do
    p_45964 = Procedure.find(45964)
    p_55824 = Procedure.find(55824)
    Benchmark.bm do |x|
      x.report("Démarche 45964") { PiecesJustificativesService.generate_dossier_export(p_45964.dossiers) }
      x.report("Démarche 55824") { PiecesJustificativesService.generate_dossier_export(p_55824.dossiers.limit(10_000)) }
    end
  end
end
