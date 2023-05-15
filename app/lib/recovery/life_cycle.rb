module Recovery
  class LifeCycle
    def initialize(dossier_ids:)
      @dossier_ids = dossier_ids
    end

    def load_export_destroy_and_import
      export_dossiers
      destroy_dossiers
      import_dossiers
    end

    def exporter
      @exporter ||= Recovery::Exporter.new(dossier_ids: @dossier_ids)
    end

    def importer
      @importer ||= Importer.new()
    end

    def export_dossiers
      exporter.dump
    end

    def destroy_dossiers
      Dossier.where(id: @dossier_ids).destroy_all
    end

    def import_dossiers
      importer.load
    end
  end
end
