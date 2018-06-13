require Rails.root.join("lib", "tasks", "task_helper")

namespace :'2018_06_05_send_new_attestation' do
  task set: :environment do
    ids = [
      20982,
      21262,
      54914,
      59769,
      63747,
      59520,
      21496,
      13386,
      13371,
      14585,
      15307,
      17212,
      16037,
      60403,
      60400,
      20534,
      60123,
      16361,
      16359,
      57147,
      51979,
      49632,
      48628,
      48624,
      22077,
      41103
    ]

    dossiers = ids.map { |id| Dossier.find_by(id: id) }.compact

    dossiers.each do |dossier|
      attestation = dossier.attestation

      if attestation
        id = attestation.id
        attestation.destroy
        rake_puts "Attestation #{id} détruite"
      end

      dossier.attestation = dossier.build_attestation

      NewAttestationMailer.new_attestation(dossier).deliver_later
      rake_puts "Email envoyé à #{dossier.user.email} pour le dossier #{dossier.id}"
      rake_puts
    end
  end
end
