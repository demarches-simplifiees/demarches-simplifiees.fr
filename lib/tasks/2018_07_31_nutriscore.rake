require Rails.root.join("lib", "tasks", "task_helper")

namespace :'2018_07_31_nutriscore' do
  task migrate_dossiers: :environment do
    source_procedure_id = ENV['SOURCE_PROCEDURE_ID'] || 4861
    destination_procedure_id = ENV['DESTINATION_PROCEDURE_ID'] || 7009

    source_procedure = Procedure.find(source_procedure_id)
    destination_procedure = Procedure.find(destination_procedure_id)

    mapping = Class.new(Tasks::DossierProcedureMigrator::ChampMapping) do
      def setup_mapping
        siret_order_place = 2
        fonction_order_place = 9
        zone_geographique_header_order_place = 18
        pays_commercialisation_order_place = 19
        header_engagement_order_place = 20

        champ_opts = { header_engagement_order_place => { source_overrides: { 'libelle' => 'PARTIE 3 : ENGAGEMENT DE L’EXPLOITANT' }, destination_overrides: { 'libelle' => 'PARTIE 4 : ENGAGEMENT DE L’EXPLOITANT' } } }

        pays_drop_down_values = "FRANCE\r\nACORES, MADERE\r\nAFGHANISTAN\r\nAFRIQUE DU SUD\r\nALASKA\r\nALBANIE\r\nALGERIE\r\nALLEMAGNE\r\nANDORRE\r\nANGOLA\r\nANGUILLA\r\nANTIGUA-ET-BARBUDA\r\nANTILLES NEERLANDAISES\r\nARABIE SAOUDITE\r\nARGENTINE\r\nARMENIE\r\nARUBA\r\nAUSTRALIE\r\nAUTRICHE\r\nAZERBAIDJAN\r\nBAHAMAS\r\nBAHREIN\r\nBANGLADESH\r\nBARBADE\r\nBELGIQUE\r\nBELIZE\r\nBENIN\r\nBERMUDES\r\nBHOUTAN\r\nBIELORUSSIE\r\nBIRMANIE\r\nBOLIVIE\r\nBONAIRE, SAINT EUSTACHE ET SABA\r\nBOSNIE-HERZEGOVINE\r\nBOTSWANA\r\nBOUVET (ILE)\r\nBRESIL\r\nBRUNEI\r\nBULGARIE\r\nBURKINA\r\nBURUNDI\r\nCAIMANES (ILES)\r\nCAMBODGE\r\nCAMEROUN\r\nCAMEROUN ET TOGO\r\nCANADA\r\nCANARIES (ILES)\r\nCAP-VERT\r\nCENTRAFRICAINE (REPUBLIQUE)\r\nCHILI\r\nCHINE\r\nCHRISTMAS (ILE)\r\nCHYPRE\r\nCLIPPERTON (ILE)\r\nCOCOS ou KEELING (ILES)\r\nCOLOMBIE\r\nCOMORES\r\nCONGO\r\nCONGO (REPUBLIQUE DEMOCRATIQUE)\r\nCOOK (ILES)\r\nCOREE\r\nCOREE (REPUBLIQUE DE)\r\nCOREE (REPUBLIQUE POPULAIRE DEMOCRATIQUE DE)\r\nCOSTA RICA\r\nCOTE D'IVOIRE\r\nCROATIE\r\nCUBA\r\nCURAÇAO\r\nDANEMARK\r\nDJIBOUTI\r\nDOMINICAINE (REPUBLIQUE)\r\nDOMINIQUE\r\nEGYPTE\r\nEL SALVADOR\r\nEMIRATS ARABES UNIS\r\nEQUATEUR\r\nERYTHREE\r\nESPAGNE\r\nESTONIE\r\nETATS MALAIS NON FEDERES\r\nETATS-UNIS\r\nETHIOPIE\r\nEX-REPUBLIQUE YOUGOSLAVE DE MACEDOINE\r\nFEROE (ILES)\r\nFIDJI\r\nFINLANDE\r\nGABON\r\nGAMBIE\r\nGEORGIE\r\nGEORGIE DU SUD ET LES ILES SANDWICH DU SUD\r\nGHANA\r\nGIBRALTAR\r\nGOA\r\nGRECE\r\nGRENADE\r\nGROENLAND\r\nGUADELOUPE\r\nGUAM\r\nGUATEMALA\r\nGUERNESEY\r\nGUINEE\r\nGUINEE EQUATORIALE\r\nGUINEE-BISSAU\r\nGUYANA\r\nGUYANE\r\nHAITI\r\nHAWAII (ILES)\r\nHEARD ET MACDONALD (ILES)\r\nHONDURAS\r\nHONG-KONG\r\nHONGRIE\r\nILES PORTUGAISES DE L'OCEAN INDIEN\r\nINDE\r\nINDONESIE\r\nIRAN\r\nIRAQ\r\nIRLANDE, ou EIRE\r\nISLANDE\r\nISRAEL\r\nITALIE\r\nJAMAIQUE\r\nJAPON\r\nJERSEY\r\nJORDANIE\r\nKAMTCHATKA\r\nKAZAKHSTAN\r\nKENYA\r\nKIRGHIZISTAN\r\nKIRIBATI\r\nKOSOVO\r\nKOWEIT\r\nLA REUNION\r\nLABRADOR\r\nLAOS\r\nLESOTHO\r\nLETTONIE\r\nLIBAN\r\nLIBERIA\r\nLIBYE\r\nLIECHTENSTEIN\r\nLITUANIE\r\nLUXEMBOURG\r\nMACAO\r\nMADAGASCAR\r\nMALAISIE\r\nMALAWI\r\nMALDIVES\r\nMALI\r\nMALOUINES, OU FALKLAND (ILES)\r\nMALTE\r\nMAN (ILE)\r\nMANDCHOURIE\r\nMARIANNES DU NORD (ILES)\r\nMAROC\r\nMARSHALL (ILES)\r\nMARTINIQUE\r\nMAURICE\r\nMAURITANIE\r\nMAYOTTE\r\nMEXIQUE\r\nMICRONESIE (ETATS FEDERES DE)\r\nMOLDAVIE\r\nMONACO\r\nMONGOLIE\r\nMONTENEGRO\r\nMONTSERRAT\r\nMOZAMBIQUE\r\nNAMIBIE\r\nNAURU\r\nNEPAL\r\nNICARAGUA\r\nNIGER\r\nNIGERIA\r\nNIUE\r\nNORFOLK (ILE)\r\nNORVEGE\r\nNOUVELLE-CALEDONIE\r\nNOUVELLE-ZELANDE\r\nOCEAN INDIEN (TERRITOIRE BRITANNIQUE DE L')\r\nOMAN\r\nOUGANDA\r\nOUZBEKISTAN\r\nPAKISTAN\r\nPALAOS (ILES)\r\nPALESTINE (Etat de)\r\nPANAMA\r\nPAPOUASIE-NOUVELLE-GUINEE\r\nPARAGUAY\r\nPAYS-BAS\r\nPEROU\r\nPHILIPPINES\r\nPITCAIRN (ILE)\r\nPOLOGNE\r\nPOLYNESIE FRANCAISE\r\nPORTO RICO\r\nPORTUGAL\r\nPOSSESSIONS BRITANNIQUES AU PROCHE-ORIENT\r\nPRESIDES\r\nPROVINCES ESPAGNOLES D'AFRIQUE\r\nQATAR\r\nREPUBLIQUE DEMOCRATIQUE ALLEMANDE\r\nREPUBLIQUE FEDERALE D'ALLEMAGNE\r\nROUMANIE\r\nROYAUME-UNI\r\nRUSSIE\r\nRWANDA\r\nSAHARA OCCIDENTAL\r\nSAINT-BARTHELEMY\r\nSAINT-CHRISTOPHE-ET-NIEVES\r\nSAINT-MARIN\r\nSAINT-MARTIN\r\nSAINT-MARTIN (PARTIE NEERLANDAISE)\r\nSAINT-PIERRE-ET-MIQUELON\r\nSAINT-VINCENT-ET-LES GRENADINES\r\nSAINTE HELENE, ASCENSION ET TRISTAN DA CUNHA\r\nSAINTE-LUCIE\r\nSALOMON (ILES)\r\nSAMOA AMERICAINES\r\nSAMOA OCCIDENTALES\r\nSAO TOME-ET-PRINCIPE\r\nSENEGAL\r\nSERBIE\r\nSEYCHELLES\r\nSIBERIE\r\nSIERRA LEONE\r\nSINGAPOUR\r\nSLOVAQUIE\r\nSLOVENIE\r\nSOMALIE\r\nSOUDAN\r\nSOUDAN ANGLO-EGYPTIEN, KENYA, OUGANDA\r\nSOUDAN DU SUD\r\nSRI LANKA\r\nSUEDE\r\nSUISSE\r\nSURINAME\r\nSVALBARD et ILE JAN MAYEN\r\nSWAZILAND\r\nSYRIE\r\nTADJIKISTAN\r\nTAIWAN\r\nTANGER\r\nTANZANIE\r\nTCHAD\r\nTCHECOSLOVAQUIE\r\nTCHEQUE (REPUBLIQUE)\r\nTERR. DES ETATS-UNIS D'AMERIQUE EN AMERIQUE\r\nTERR. DES ETATS-UNIS D'AMERIQUE EN OCEANIE\r\nTERR. DU ROYAUME-UNI DANS L'ATLANTIQUE SUD\r\nTERRE-NEUVE\r\nTERRES AUSTRALES FRANCAISES\r\nTERRITOIRES DU ROYAUME-UNI AUX ANTILLES\r\nTHAILANDE\r\nTIMOR ORIENTAL\r\nTOGO\r\nTOKELAU\r\nTONGA\r\nTRINITE-ET-TOBAGO\r\nTUNISIE\r\nTURKESTAN RUSSE\r\nTURKMENISTAN\r\nTURKS ET CAIQUES (ILES)\r\nTURQUIE\r\nTURQUIE D'EUROPE\r\nTUVALU\r\nUKRAINE\r\nURUGUAY\r\nVANUATU\r\nVATICAN, ou SAINT-SIEGE\r\nVENEZUELA\r\nVIERGES BRITANNIQUES (ILES)\r\nVIERGES DES ETATS-UNIS (ILES)\r\nVIET NAM\r\nVIET NAM DU NORD\r\nVIET NAM DU SUD\r\nWALLIS-ET-FUTUNA\r\nYEMEN\r\nYEMEN (REPUBLIQUE ARABE DU)\r\nYEMEN DEMOCRATIQUE\r\nZAMBIE\r\nZANZIBAR\r\nZIMBABWE"

        ((0..(zone_geographique_header_order_place - 1)).to_a - [siret_order_place, fonction_order_place]).each do |i|
          map_source_to_destination_champ(i, i, **(champ_opts[i] || {}))
        end

        ((pays_commercialisation_order_place + 1)..25).each do |i|
          map_source_to_destination_champ(i - 2, i, **(champ_opts[i] || {}))
        end

        discard_source_champ(
          TypeDeChamp.new(
            type_champ: 'text',
            order_place: siret_order_place,
            libelle: 'Numéro SIRET'
          )
        )

        discard_source_champ(
          TypeDeChamp.new(
            type_champ: 'text',
            order_place: fonction_order_place,
            libelle: 'Fonction'
          )
        )

        compute_destination_champ(
          TypeDeChamp.new(
            type_champ: 'text',
            order_place: fonction_order_place,
            libelle: 'Fonction',
            mandatory: true
          )
        ) do |d, target_tdc|
          c = d.champs.joins(:type_de_champ).find_by(types_de_champ: { order_place: fonction_order_place })

          target_tdc.champ.create(
            value: c&.value || 'Non renseigné',
            dossier: d
          )
        end

        compute_destination_champ(
          TypeDeChamp.new(
            type_champ: 'siret',
            order_place: siret_order_place,
            libelle: 'Numéro SIRET'
          )
        ) do |d, target_tdc|
          target_tdc.champ.create(
            value: d.etablissement&.siret,
            etablissement: d.etablissement,
            dossier: d
          )
        end

        compute_destination_champ(
          TypeDeChamp.new(
            type_champ: 'header_section',
            order_place: 18,
            libelle: 'PARTIE 3 : ZONE GEOGRAPHIQUE'
          )
        ) do |d, target_tdc|
          target_tdc.champ.create(dossier: d)
        end

        compute_destination_champ(
          TypeDeChamp.new(
            type_champ: 'multiple_drop_down_list',
            order_place: 19,
            libelle: 'Pays de commercialisation',
            drop_down_list: DropDownList.new(value: pays_drop_down_values)
          )
        ) do |d, target_tdc|
          target_tdc.champ.create(dossier: d, value: JSON.unparse(['FRANCE']))
        end
      end
    end

    Tasks::DossierProcedureMigrator.new(source_procedure, destination_procedure, mapping).migrate_procedure
    AutoReceiveDossiersForProcedureJob.set(cron: "* * * * *").perform_later(destination_procedure_id, 'accepte')
  end
end
