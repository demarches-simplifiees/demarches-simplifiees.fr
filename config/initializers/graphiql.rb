DEFAULT_QUERY = "# La documentation officielle de la spécification (Anglais) : https://graphql.org/
# Une introduction aux concepts et raisons d'être de GraphQL (Français) : https://blog.octo.com/graphql-et-pourquoi-faire/
# Le schema GraphQL de demarches-simplifiees.fr : https://demarches-simplifiees-graphql.netlify.com
# Le endpoint GraphQL de demarches-simplifiees.fr : https://www.demarches-simplifiees.fr/api/v2/graphql

query getDemarche($demarcheNumber: Int!) {
  demarche(number: $demarcheNumber) {
    id
    number
    title
    champDescriptors {
      id
      type
      label
    }
    dossiers(first: 3) {
      nodes {
        id
        number
        datePassageEnConstruction
        datePassageEnInstruction
        dateTraitement
        usager {
          email
        }
        champs {
          id
          label
          ... on TextChamp {
            value
          }
          ... on DecimalNumberChamp {
            value
          }
          ... on IntegerNumberChamp {
            value
          }
          ... on CheckboxChamp {
            value
          }
          ... on DateChamp {
            value
          }
          ... on DossierLinkChamp {
            dossier {
              id
            }
          }
          ... on MultipleDropDownListChamp {
            values
          }
          ... on LinkedDropDownListChamp {
            primaryValue
            secondaryValue
          }
          ... on PieceJustificativeChamp {
            file {
              url
            }
          }
          ... on CarteChamp {
            geoAreas {
              source
              geometry {
                type
                coordinates
              }
            }
          }
        }
      }
      pageInfo {
        hasNextPage
        endCursor
      }
    }
  }
}"

GraphiQL::Rails.config.initial_query = DEFAULT_QUERY
GraphiQL::Rails.config.title = 'demarches-simplifiees.fr'
