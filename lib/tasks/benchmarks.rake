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

  desc 'Attestation Template parser'
  task attestation_template_parser: :environment do
    procedure = Procedure.find(68139)
    Benchmark.bm do |x|
      x.report("Empty") { TagsSubstitutionConcern::TagsParser.parse('') }
      x.report("Démarche 68139") { TagsSubstitutionConcern::TagsParser.parse(procedure.attestation_template.body) }
    end
  end

  # Benchmark une action Rails spécifique, y compris le temps de génération des views.
  # Optionnellement, compare avec une autre implémentation de l'action
  # sur la même branche ou sur deux branches git.
  #
  # Le benchmark se fait en deux temps (2 processes ruby séparés à lancer l'un après l'autre)
  # en stockant les résultats intermédiaires dans un fichier.
  #
  # === Prérequis ===
  #
  # 1. On fake l'authentification. Commenter le `before_action :authenticate_*` concerné
  #
  # 2. Override dans le controller le(s) `current_*` concernés
  #
  #    Par exemple :
  #
  #    def current_instructeur
  #      @current_instructeur ||= Instructeur.find(12_345)
  #    end
  #
  # 3. Pour se rapprocher un peu plus de l'environnement de prod, activer le cache:
  #    `rails dev:cache` puis redémarrer le serveur (à refaire à la fin pour l'enlever)
  #
  # 4a. Pour comparer l'implémentation de deux actions sur la même branche (par ex `index` et `index_main`):
  #    la seconde implémentation doit :
  #    - avoir une route définie (ie. `get :index_main`)
  #    - adapter les `before_action`
  #    - la conclure par `render :index` si la vue est identique, ou adapter les vues.
  #
  #    Exécuter 2 foix:
  #
  #    rake benchmarks:action[Instructeurs::ProceduresController,index,index_main]
  #
  # 4b. Pour comparer l'implémentation d'une même action sur 2 branches,
  #     exécuter sur chacune d'entre elle :
  #
  #     rake benchmarks:action[Instructeurs::ProceduresController,index,index]
  #
  #     Attention : penser à refaire les étapes 1 et 2 sur la seconde branche !
  #
  desc "Benchmark a Rails action"
  task :action, [:controller, :action1, :action2] => :environment do |_, args|
    require 'benchmark/ips'

    controller_class = args[:controller].constantize
    action1_name = args[:action1]
    action2_name = args[:action2]

    warden_mock = Struct.new(:user) do
      def authenticate(*_args); end
    end

    warden = warden_mock.new(nil)

    setup_controller_instance = Proc.new do |controller_class, warden|
      controller = controller_class.new
      controller.request = ActionDispatch::TestRequest.create
      controller.response = ActionDispatch::TestResponse.new
      controller.request.env['warden'] = warden
      controller
    end

    Benchmark.ips do |x|
      x.config(time: 30, warmup: 10)
      x.hold! 'tmp/benchmarks_action_hold' # run in different processes so we can switch branches

      x.report("#{controller_class}##{action1_name}1") do
        controller = setup_controller_instance.call(controller_class, warden)
        controller.process(action1_name)
      end

      if action2_name
        x.report("#{controller_class}##{action2_name}2") do
          controller = setup_controller_instance.call(controller_class, warden)
          controller.process(action2_name)
        end
      end

      x.compare!
    end
  end
end
