---
category: "administrateur"
subcategory: "general"
slug: "les-blocs-repetables"
locale: "fr"
keywords: "blocs répétables, champs dynamiques, saisie multiple, configuration champ"
title: "Les blocs répétables"
---

# Les blocs répétables

Les blocs répétables sont une fonctionnalité qui permet à l’usager de saisir un certain nombre de champs autant de fois qu’il le souhaite.


## Exemple d’utilisation

Imaginez une situation où l’usager doit saisir plusieurs fois une commune. L’administrateur prévoit une seule fois ce « bloc » d’informations (champ commune), et l’usager peut ensuite le saisir autant de fois que nécessaire.


## Comment configurer un bloc répétable ?

1. Sélectionnez comme type de champ le **« Bloc répétable »** et ajoutez son libellé. Dans notre exemple ce sera *Localisation*.
  ![Exemple de choix du champ Bloc répétable](faq/administrateur-list-champs-repetition.png)

2. Renseignez les différents champs à inclure au sein de ce bloc répétable en cliquant sur **« Ajouter un champ »** à l’intérieur du bloc. Vous pouvez ajouter tous les types de champ (texte, zone de texte, entier, etc…)
  Dans l’exemple d’une liste de communes, l’administrateur ajoute donc le champ « Commune » mais d’autres champs pourraient être ajoutés.
  ![Exemple de configuration d’une répétition](faq/administrateur-repetition-create.png)

## Comment fonctionne-t-il pour l’usager ?

- L’usager voit le champ répétable, vide par défaut, et peut cliquer sur **« Ajouter un élément »** pour saisir une nouvelle instance du bloc.
  ![Vue usager vide du bloc répétable](faq/administrateur-repetition-view-usager-empty.png)

- Après avoir ajouté un élément, il peut continuer à ajouter de nouvelles valeurs aussi souvent que nécessaire.
  ![Vue usager remplie avec 2 communes du bloc répétable](faq/administrateur-repetition-view-usager-fill.png)

- Si nécessaire, l’usager a la possibilité de supprimer un élément précédemment ajouté.

Les blocs répétables simplifient grandement la saisie de données multiples.
