# frozen_string_literal: true

module APIParticulier
  module Services
    class SourcesService
      def initialize(procedure)
        @procedure = procedure
      end

      def available_sources
        @procedure.api_particulier_scopes
          .filter_map { |provider_and_scope| raw_scopes[provider_and_scope] }
          .uniq # remove provider/scope tuples duplicates (e.g. mesri inscriptions)
          .map { |provider, scope| extract_sources(provider, scope) }
          .reduce({}) { |acc, el| acc.deep_merge(el) { |_, this_val, other_val| this_val + other_val } }
      end

      # Remove sources not available for the procedure
      def sanitize(requested_sources)
        requested_sources_a = h_to_a(requested_sources)
        available_sources_a = h_to_a(available_sources)

        filtered_sources_a = requested_sources_a.intersection(available_sources_a)

        a_to_h(filtered_sources_a)
      end

      private

      # { 'cnaf' => { 'scope' => ['a', 'b'] }} => [['cnaf', 'scope', 'a'], ['cnaf', 'scope', 'b']]
      def h_to_a(h)
        h.reduce([]) { |acc, (provider, scopes)| scopes.each { |scope, values| values.each { |s, _| acc << [provider, scope, s] } }; acc }
      end

      # [['cnaf', 'scope', 'a'], ['cnaf', 'scope', 'b']] => { 'cnaf' => { 'scope' => ['a', 'b'] }}
      def a_to_h(a)
        h = Hash.new { |h, k| h[k] = Hash.new { |h2, k2| h2[k2] = [] } }

        a.reduce(h) { |acc, (provider, scope, source)| h[provider][scope] << source; acc }
      end

      def extract_sources(provider, scope)
        provider_scope_value = providers[provider][scope]

        case provider_scope_value
        when Hash
          { provider => provider_scope_value }
        else
          { provider => { scope => Array(provider_scope_value) } }
        end
      end

      def raw_scopes
        {
          'cnaf_allocataires' => ['cnaf', 'allocataires'],
          'cnaf_enfants' => ['cnaf', 'enfants'],
          'cnaf_adresse' => ['cnaf', 'adresse'],
          'cnaf_quotient_familial' => ['cnaf', 'quotient_familial'],
          'dgfip_declarant1_nom' => ['dgfip', 'declarant1_nom'],
          'dgfip_declarant1_nom_naissance' => ['dgfip', 'declarant1_nom_naissance'],
          'dgfip_declarant1_prenoms' => ['dgfip', 'declarant1_prenoms'],
          'dgfip_declarant1_date_naissance' => ['dgfip', 'declarant1_date_naissance'],
          'dgfip_declarant2_nom' => ['dgfip', 'declarant2_nom'],
          'dgfip_declarant2_nom_naissance' => ['dgfip', 'declarant2_nom_naissance'],
          'dgfip_declarant2_prenoms' => ['dgfip', 'declarant2_prenoms'],
          'dgfip_declarant2_date_naissance' => ['dgfip', 'declarant2_date_naissance'],
          'dgfip_date_recouvrement' => ['dgfip', 'date_recouvrement'],
          'dgfip_date_etablissement' => ['dgfip', 'date_etablissement'],
          'dgfip_adresse_fiscale_taxation' => ['dgfip', 'adresse_fiscale_taxation'],
          'dgfip_adresse_fiscale_annee' => ['dgfip', 'adresse_fiscale_annee'],
          'dgfip_nombre_parts' => ['dgfip', 'nombre_parts'],
          'dgfip_nombre_personnes_a_charge' => ['dgfip', 'nombre_personnes_a_charge'],
          'dgfip_situation_familiale' => ['dgfip', 'situation_familiale'],
          'dgfip_revenu_brut_global' => ['dgfip', 'revenu_brut_global'],
          'dgfip_revenu_imposable' => ['dgfip', 'revenu_imposable'],
          'dgfip_impot_revenu_net_avant_corrections' => ['dgfip', 'impot_revenu_net_avant_corrections'],
          'dgfip_montant_impot' => ['dgfip', 'montant_impot'],
          'dgfip_revenu_fiscal_reference' => ['dgfip', 'revenu_fiscal_reference'],
          'dgfip_annee_impot' => ['dgfip', 'annee_impot'],
          'dgfip_annee_revenus' => ['dgfip', 'annee_revenus'],
          'dgfip_erreur_correctif' => ['dgfip', 'erreur_correctif'],
          'dgfip_situation_partielle' => ['dgfip', 'situation_partielle'],
          'pole_emploi_identite' => ['pole_emploi', 'identite'],
          'pole_emploi_adresse' => ['pole_emploi', 'adresse'],
          'pole_emploi_contact' => ['pole_emploi', 'contact'],
          'pole_emploi_inscription' => ['pole_emploi', 'inscription'],
          'mesri_identifiant' => ['mesri', 'identifiant'],
          'mesri_identite' => ['mesri', 'identite'],
          'mesri_inscription_etudiant' => ['mesri', 'inscriptions'],
          'mesri_inscription_autre' => ['mesri', 'inscriptions'],
          'mesri_admission' => ['mesri', 'admissions'],
          'mesri_etablissements' => ['mesri', 'etablissements'],
        }
      end

      def providers
        {
          'cnaf' => {
            'allocataires' => ['nomPrenom', 'dateDeNaissance', 'sexe'],
            'enfants' => ['nomPrenom', 'dateDeNaissance', 'sexe'],
            'adresse' => ['identite', 'complementIdentite', 'complementIdentiteGeo', 'numeroRue', 'lieuDit', 'codePostalVille', 'pays'],
            'quotient_familial' => ['quotientFamilial', 'annee', 'mois'],
          },
          'dgfip' => {
            'declarant1_nom' => { 'declarant1' => ['nom'] },
            'declarant1_nom_naissance' => { 'declarant1' => ['nomNaissance'] },
            'declarant1_prenoms' => { 'declarant1' => ['prenoms'] },
            'declarant1_date_naissance' => { 'declarant1' => ['dateNaissance'] },
            'declarant2_nom' => { 'declarant2' => ['nom'] },
            'declarant2_nom_naissance' => { 'declarant2' => ['nomNaissance'] },
            'declarant2_prenoms' => { 'declarant2' => ['prenoms'] },
            'declarant2_date_naissance' => { 'declarant2' => ['dateNaissance'] },
            'date_recouvrement' => { 'echeance_avis' => ['dateRecouvrement'] },
            'date_etablissement' => { 'echeance_avis' => ['dateEtablissement'] },
            'adresse_fiscale_taxation' => { 'foyer_fiscal' => ['adresse'] },
            'adresse_fiscale_annee' => { 'foyer_fiscal' => ['annee'] },
            'nombre_parts' => { 'foyer_fiscal' => ['nombreParts'] },
            'nombre_personnes_a_charge' => { 'foyer_fiscal' => ['nombrePersonnesCharge'] },
            'situation_familiale' => { 'foyer_fiscal' => ['situationFamille'] },
            'revenu_brut_global' => { 'agregats_fiscaux' => ['revenuBrutGlobal'] },
            'revenu_imposable' => { 'agregats_fiscaux' => ['revenuImposable'] },
            'impot_revenu_net_avant_corrections' => { 'agregats_fiscaux' => ['impotRevenuNetAvantCorrections'] },
            'montant_impot' => { 'agregats_fiscaux' => ['montantImpot'] },
            'revenu_fiscal_reference' => { 'agregats_fiscaux' => ['revenuFiscalReference'] },
            'annee_impot' => { 'agregats_fiscaux' => ['anneeImpots'] },
            'annee_revenus' => { 'agregats_fiscaux' => ['anneeRevenus'] },
            'erreur_correctif' => { 'complements' => ['erreurCorrectif'] },
            'situation_partielle' => { 'complements' => ['situationPartielle'] },
          },
          'pole_emploi' => {
            'identite' => ['identifiant', 'civilite', 'nom', 'nomUsage', 'prenom', 'sexe', 'dateNaissance'],
            'adresse' => ['INSEECommune', 'codePostal', 'localite', 'ligneVoie', 'ligneComplementDestinataire', 'ligneComplementAdresse', 'ligneComplementDistribution', 'ligneNom'],
            'contact' => ['email', 'telephone', 'telephone2'],
            'inscription' => ['dateInscription', 'dateCessationInscription', 'codeCertificationCNAV', 'codeCategorieInscription', 'libelleCategorieInscription'],
          },
          'mesri' => {
            'identifiant' => ['ine'],
            'identite' => ['nom', 'prenom', 'dateNaissance'],
            'inscriptions' => ['statut', 'regime', 'dateDebutInscription', 'dateFinInscription', 'codeCommune'],
            'admissions' => ['statut', 'regime', 'dateDebutAdmission', 'dateFinAdmission', 'codeCommune'],
            'etablissements' => ['uai', 'nom'],
          },
        }
      end
    end
  end
end
