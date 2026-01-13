# Comment contribuer

demarche.numerique.gouv.fr est un [logiciel libre](https://fr.wikipedia.org/wiki/Logiciel_libre). Vous pouvez lire et modifier son code-source, sous les termes de la licence AGPL.

Si vous souhaitez apporter des améliorations à demarche.numerique.gouv.fr, c’est possible !

Le mieux pour cela est de **proposer une modification dans la base de code principale**. Une fois acceptée, votre amélioration sera ainsi disponible pour l’ensemble des utilisateurs de demarche.numerique.gouv.fr.

Voici la marche à suivre recommandée pour effectuer une modification.

## 1. Discuter de l’amélioration

La première étape est généralement de discuter de l’amélioration que vous proposez (s’il ne s’agit pas d’un changement trivial, comme la correction d’une coquille).

Pour cela, [créez une nouvelle issue](https://github.com/demarche-numerique/demarche.numerique.gouv.fr/issues/new) concernant votre proposition. Autant que possible, indiquez clairement votre besoin, votre cas d’usage – et éventuellement comment vous pensez déjà le résoudre.

Nous pouvons alors discuter, pour vérifier que le besoin exprimé correspond à l’usage de demarche.numerique.gouv.fr, proposer éventuellement des alternatives, et se mettre d’accord sur une implémentation technique pertinente.

## 2. Proposer du code

Une fois que la discussion est établie, et que les éléments techniques sont dégrossis, vous pouvez proposer des changements au code. Pour cela, effectuez vos modifications en local, et [ouvrez une Pull Request](https://github.com/demarche-numerique/demarche.numerique.gouv.fr/issues/new) avec les changements que vous souhaitez apporter.

Quelques conseils : pensez à bien décrire l’objectif et l’implémentation de votre PR au moment de la créer. Et si vos changements sont importants, découpez-les en plusieurs petites PRs successives, qui seront plus faciles à relire. N’oubliez pas d’ajouter des tests automatisés pour vous assurer que vos changements fonctionnent bien.

Chaque PR ouverte déclenche l’exécution des tests automatisés, et la vérification du format du code. Si vos tests ou votre formatage sont en rouge, corrigez les erreurs avant de continuer.

Une personne de l’équipe de développement fera une relecture, en demandant éventuellement des détails ou des changements. Si personne n’a réagi au bout de 5 jours, n’hésitez pas à relancer en ajoutant un commentaire à la PR.

## 3. Intégration

Une fois votre PR approuvée, elle sera intégrée dans la base de code principale.

Nous mettons en production au minimum une fois par semaine (et généralement plus) : vos changements seront disponibles en production sur [demarche.numerique.gouv.fr](https://demarche.numerique.gouv.fr) quelques jours après.

## Héberger demarche.numerique.gouv.fr

demarche.numerique.gouv.fr est **compliqué à héberger**. Parmi les problématiques que nous rencontrons :

- **Sécurité et confidentialité des données** : par nature, demarche.numerique.gouv.fr est appelé à traiter des natures de données qui peuvent présenter des caractéristiqus plus ou moins sensibles. La sécurité de l’infrastructure doit être contrôlée et certifiée pour garantir la confidentialité des données. Cela implique par exemple une démarche de mise en conformité avec le [Référentiel Général de Sécurité](https://www.ssi.gouv.fr/entreprise/reglementation/confiance-numerique/le-referentiel-general-de-securite-rgs/), qui est un processus assez lourd.
  C’est également valable pour le stockage des pièces-jointes, qui peuvent la aussi présenter des particularités et des sensibilités dont la confidentialité doit être garantie.

  Le chiffrement des pièces jointes est assurée par notre proxy HTTP [DS Proxy](https://github.com/demarche-numerique/ds_proxy) (mais il est optionnel).

- **Utilisation de services externes** : demarche.numerique.gouv.fr s’interconnecte à de nombreux services externes : des APIs (API Entreprise, API Carto, la Base Adresse Nationale, etc.) – mais aussi des services pour le stockage externe des pièces-jointes, l’analyse anti-virus ou l’envoi des emails. Le fonctionnement de demarche.numerique.gouv.fr dépend de la disponibilité de ces services externes.
- **Mises à jour** : le schéma de la base de données change régulièrement. Nous codons également des scripts pour harmoniser les anciennes données. Parfois des modifications ponctuelles sont effectuées sur des démarches anciennes, pour les mettre en conformité avec de nouvelles règles métiers. Nous maintenons également les dépendances logicielles utilisées – notamment en réagissant rapidement lorsqu’une faille de sécurité est signalée. Ces mises à jour fréquentes en production sont indispensables au bon fonctionnement de l’outil.

Si vous souhaitez adapter demarche.numerique.gouv.fr à vos besoins, nous vous recommandons de **proposer vos modifications à la base de code principale** (par exemple en créant une issue) **plutôt que d’héberger une autre instance vous-même**.

Dans le cas où vous envisagez d’héberger une instance de demarche.numerique.gouv.fr vous-même, nous ne disposons malheureusement pas des moyens pour vous accompagner, ni d’assurer de support technique concernant votre installation.

Toutefois, certains acteurs (le ministère des armées, l’administration autonome en Polynésie française, l’association Adullact) ont déployé des instances séparées. Nous proposons aux personnes intéressées de les mettre en relation avec ces acteurs existants, pour obtenir un retour d’expérience et bénéficier de leur retour.

## Bonnes pratiques de code

Votre contribution sera plus rapidement traitée si elle s’appuie sur nos habitudes de développement.

Nous travaillons à rendre explicite un maximum de nos pratiques de dev, aussi il est chaudement recommandé
de prendre connaissance des [bonnes pratiques de code](doc/Contributions/Pratiques-de-dev.md).

Merci de votre intérêt pour le projet !
