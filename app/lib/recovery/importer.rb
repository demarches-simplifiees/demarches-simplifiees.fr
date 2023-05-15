module Recovery
  class Importer
    attr_reader :dossiers

    def initialize(file_path: Recovery::Exporter::FILE_PATH)
      @dossiers = Marshal.load(File.read(file_path))
    end

    def load
      @dossiers.map do |dossier|
        dossier.instance_variable_set :@new_record, true
        dossier.save!
      end
    end
  end
end

