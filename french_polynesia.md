This journal lists modifications built on top of demarches-simplifiees.

# champs specifiques à la Polynésie française

| Champ                    | Label                                                                                                                                                                 |
|--------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Numero DN                | A way to enter a DN number composed of two fields : a number and date of birth                                                                                        |
| commune de Polynésie     | dropdown list of french Polynesia cities with island & archipel                                                                                                       |
| code postal de Polynésie | dropdown list of french postal codes                                                                                                                                  |
| nationalites             | dropdown list of nationalities                                                                                                                                        |
| te_fenua                 | map of polynesia using OpenLayer as a foundation                                                                                                                      |
| Visa                     | Checkbox accessible to predefined list of people. When checked, Visa records who checked the visa and disable all fields above in the current level 1 header section. |
|                          | Admin may set min,max limits                                                                                                                                          |

# Différences fonctionnelles avec démarches simplifiées

| date      | titre                               | description                                                                                                                                                                                   |
|-----------|-------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| -         | Siret vs Numero TAHITI              | Le numéro TAHITI est l'équivalent français du numéro Siren. Pour l'instant le numéro Tahiti est considéré comme un numéro Siret et tooute l'interface est changées en conséquence.            |
| -         | Lien dans les commentaires          | Les liens envoyés par les instructeurs dans les commentaires sont directement clicables                                                                                                       |
| -         | Integer, Decimal, Date              | L'administrateur a la possibilité de définir des valeurs minimales et maximales pour les champs Integer, Decimal et Date.                                                                     |
| -         | Description des champs              | La description des champ peut contenir des sous-listes à des listes                                                                                                                           |
| -         | Description des champs              | La description d'un champ peut contenir les balises des balises <img>, <a>, <font>, <ol>, <ul>,<b>,<u>,<i> pour insérer des images, liens, listes, et formater le texte                       |
| -         | Connexion usager                    | L'usager peut se connecter via Google, Microsoft ou Tatou. C'est une généralisation de la connexion France Connect.                                                                           |
| -         | Complexité du mot de passe          | Les trois roles ont un niveau de complexite pour le mot de passe: Usager => 2, Instructeur => 3, Administrateur => 4                                                                          |
| -         | Connexion Microsoft                 | Les agents de l'administration de la Polynésie etant sous Office, la connexion via Microsoft est autorisée pour les comptes instructeur et administrateur                                     |
| -         | GraphQL Assigner Instructeur        | Il est possible d'assigner un dossier à un instructeur                                                                                                                                        |
| -         | GraphQL Modifier annotation         | Il est possible de modifier une liste déroulante, l'email ou un téléphone                                                                                                                     |
| -         | GraphQL Ajouter piece justificative | Il est possible d'ajouter une piece justificative à un champ                                                                                                                                  |
| -         | Mails images                        | Il est possible d'insérer des liens <img> et <a> dans les mails officiels d'une démarche                                                                                                      |
| -         | SendInBlue                          | La suppression des mails plus vieux que 6 mois est différente (à creuser)                                                                                                                     |
| -         | Publication d'une démarche          | Un mail est toujours envoyé à l'équipe lors de la publication d'une démarche (supprimé dans DS)                                                                                               |
| -         | Normalisation Nom/Prénom            | Le NOM et le PRENOM demandé au début du formulaire sont normalisés.                                                                                                                           |
| -         | Affichage des blocs répétitifs      | Les blocs s'affichent sous forme de tableau                                                                                                                                                   |
| -         | Attestation : PJ                    | Dans les attestations, les PJ s'affichent comme des liens par défaut et une icone est affiché pour les images                                                                                 |
| 11/4/2024 | Description des champs              | La fonte est légèrement plus grande pour être lisible sur téléphone                                                                                                                           | 
| 11/4/2024 | Télécharger le PDF                  | Le lien en bas du formulaire permettant de télécharger le PDF est moins visible car les usagers ont tendance à l'utiliser même quand ils remplissent le formulaire en ligne                   |
| 23/5/2024 | EQUIPE_EMAIL                        | Mail not removed as it is used to communicate on published procedures                                                                                                                         |
| 23/5/2024 | Connecté via                        | Le mail de l'usager en haut à droite affiche quel fournisseur d'identité a servi à connecter l'usager                                                                                         |
| 28/5/2024 | france_connect_informations         | DS se base sur la présence d'un FCI pour dire que l'usager est connecté via FC alors qu'il peut s'etre entre temps connecté via un mot de passe. Sur MD, on teste via le champ loged_via...   |


