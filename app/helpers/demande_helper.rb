module DemandeHelper
  def nb_of_procedures_options
    {
      'je ne sais pas' => Pipedrive::DealAdapter::PIPEDRIVE_NB_OF_PROCEDURES_DO_NOT_KNOW_VALUE,
      '1'              => Pipedrive::DealAdapter::PIPEDRIVE_NB_OF_PROCEDURES_1_VALUE,
      '1 à 10'         => Pipedrive::DealAdapter::PIPEDRIVE_NB_OF_PROCEDURES_1_TO_10_VALUE,
      '10 à 100 '      => Pipedrive::DealAdapter::PIPEDRIVE_NB_OF_PROCEDURES_10_TO_100_VALUE,
      'plus de 100'    => Pipedrive::DealAdapter::PIPEDRIVE_NB_OF_PROCEDURES_ABOVE_100_VALUE
    }
  end

  def deadline_options
    {
      'le plus vite possible'      => Pipedrive::DealAdapter::PIPEDRIVE_DEADLINE_ASAP_VALUE,
      'dans les 3 prochains mois'  => Pipedrive::DealAdapter::PIPEDRIVE_DEADLINE_NEXT_3_MONTHS_VALUE,
      'dans les 6 prochains mois'  => Pipedrive::DealAdapter::PIPEDRIVE_DEADLINE_NEXT_6_MONTHS_VALUE,
      'dans les 12 prochains mois' => Pipedrive::DealAdapter::PIPEDRIVE_DEADLINE_NEXT_12_MONTHS_VALUE,
      'pas de date'                => Pipedrive::DealAdapter::PIPEDRIVE_DEADLINE_NO_DATE_VALUE
    }
  end
end
