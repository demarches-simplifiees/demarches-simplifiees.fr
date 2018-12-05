namespace :'2018_12_03_finish_piece_jointe_transfer' do
  task run: :environment do
    Class.new do
      def run
        notify_dry_run
        notify_dry_run
      end

      def notify_dry_run
        if !force?
          rake_puts "Dry run, run with FORCE=1 to actually perform changes"
        end
      end

      def force?
        if !defined? @force
          @force = (ENV['FORCE'].presence || '0').to_i != 0
        end

        @force
      end

      def verbose?
        if !defined? @verbose
          @verbose = (ENV['VERBOSE'].presence || '0').to_i != 0
        end

        @verbose
      end
    end.new.run
  end
end
