## Premiere partie PARSER

1.
![Automate_LR0](Grammaire_test.png)

2. Nous avons plusieurs conflits shift-reduce et reduce-reduce si cette grammaire est SLR:
Etat 1 : Conflit shift-reduce.

Etat 6 : Conflit shift-reduce pour expr -> FUN T ARROW expr.
Etat 6 : Conflit reduce-reduce pour reduire soit sur expr -> FUN T ARROW expr ou expr -> expr expr.

Etat 7 : Conflit shift-reduce pour expr -> expr expr.
Etat 7 : Conflit reduce-reduce pour expr -> expr expr.

Etat 9 : Conflit shift-reduce pour expr -> LPAR expr RPAR.

Etat 11 : Conflit shift-reduce pour expression -> expr.

3. Il existe une séquence de tokens sur laquelle deux arbres de dérivations
sont possibles avec cet automate tel que "T T"
La Premiere façon en utilisante expr -> T et 
la seconde en utilisant expr -> expr expr 
Donc cela nous confirme que cette grammaire n'est pas deterministe et surtout que cette grammaire est en ambiguï.

4. Le parseur implémenté dans Parser_calc.mly choisit de traiter la séquence de tokens 
en fonction de la règle de grammaire qui correspond au premier token rencontré. 
Par exemple, si la séquence commence par FUN, comme dans FUN x = ID ARROW INT, 
il applique la règle expr pour analyser une fonction. 
Il associe x = ID, ce qui fait de x un paramètre, 
puis rencontre ARROW pour indiquer le corps de la fonction, 
qui dans cet exemple est un entier (INT). 
Le parseur crée un arbre syntaxique abstrait (AST) pour représenter la fonction avec le paramètre x et le corps INT. 
En résumé, sur cette séquence de tokens, le parseur choisit d'analyser une fonction et construit l'AST correspondant.

5. Il faudrait ajouter des priorités pour traiter correctement 
expr expr et FUN x = ID ARROW expr

En menhir, on peut définir les priorités de cette façon:
%left FUN ARROW
%left expr expr

6. Si on ajoute toutes les fonctions de built_in dans ce parseur, 
alors on va sans doute devoir rajouter les priorités vu précèdemment ainsi que cette dernière %left built_in.
De cette façon, on gére correctement l'interaction entre toutes ces règles et on peut garantir que ce parseur choisisse la bonne interprétation en cas de conflit.

7. A mon avis, en priorisant les non-terminaux distincts dans ce cas permettrait une meilleur gestion des conflits shift-reduce, et permettrait une reduction des ambiguïtés en permettant de mieux controler la structure de l'analyse syntaxique et de reduire les ambiguïtés du language.

### Seconde partie Parser Syntaxe Etendue

Dans cette section, nous avons étendu la grammaire de Mini-ML afin d'accepter une syntaxe plus lisible, en ajoutant plusieurs sucres syntaxiques courants. 
Toutes les modifications ont été faites dans les fichiers:
- language/Parser.mly
- language/ast.* (ml et mli)
- interpreter.ml
- type_system.ml

Lors de l'ajout de binop dans le projet divers fichiers on du être modifier en conséquence tels que :

- ast.*
- interpreter.ml
- type_system.ml(pour eviter le warning)

##### Ajouts effectués

1. Notation infixe des opérateurs binaires

Nous avons ajouté une notation infixe pour les opérateurs arithmétiques et logiques afin de permettre des écritures telles que e1 + e2 au lieu de + e1 e2.

Avant on avait ça :

```bash
| e1 = app_expr e2 = simple_expr { App(e1,e2,Annotation.create $loc) } 
```

Tandis que maintenant nous avons supprimé cela pour le remplacer par ceci 

```bash
expr:
| e = app_expr     { e }
| e1 = expr op = binop e2 = expr { Binop(e1, e2, op, Annotation.create $loc) }

```

Explication :

On introduit une règle infixe explicite avec une priorité définie via les déclarations %left, %right, %nonassoc en début de fichier.

Difficulté :

Des conflits shift/reduce sont apparus.
Une tentative de séparation fine via binop_expr et app_expr a été faite mais les conflits persistent,
notamment autour du token SUB.
Cette complexité provient du fait qu'on mélange expressions binaires et applications dans des niveaux différents.
Nous n'avons pas réussi à resoudre ces conflits qui sont encore visibles dans le fichier Parser.conflicts présent dans le dossier parse_files générer à la compilation.

2. Notation let avec arguments

Nous avons ajouté la possibilité d’écrire let f x y = e comme du sucre syntaxique pour let f = fun x -> fun y -> e.
En faite, on autorise "let f x y = e" en transformant les arguments en une suite de fonctions imbriquées.

Implémentation :

* Ajout d’une règle id_list pour collecter les arguments d’une fonction.
* Dans la règle req, nous utilisons List.fold_right pour transformer les arguments en applications successives de Fun

Difficultés:

Nous avons eu beaucoup de mal a résoudre les conflics shift/reduce et reduce/reduce que nous avons nous même engendrées lors de l'implémentation de cette dernière.
De plus, on a rencontré des difficultés a utilisé List.fold_right dans ce genre de contexte. (On ignoré que cela été possible à la base)

3. Moins unaire

L’expression -e est désormais interprétée comme neg e.

Implémentation :

* Dans la règle simple_expr, on ajoute un cas spécifique :
```bash
SUB e = simple_expr { App(Cst_func(UMin, Annotation.create $loc), e, Annotation.create $loc) }
```

Difficulté:

Réussir à bien distinguer la différence entre le SUB binaire du SUB unaire. Comme (-4) et (5-3) par exemple.

4. Listes constantes
Les expressions [1;2;3] sont désormais transformées en (::) 1 ((::) 2 ((::) 3 [])).

Implémentation :

* Les listes [1;2;3] sont transformées en (::) 1 ((::) 2 ((::) 3 [])). On utilise des App imbriqués avec la fonction Cat.
* Ajout des nouvelles règles list_literal et list_tail.
* On utilise List.fold_right pour construire l’arbre syntaxique représentant l’application des opérateurs :: (ou Cat dans notre AST).

Difficultés :

L’ambiguïté entre la liste vide et les listes avec éléments a été résolue avec deux productions distinctes.


Malgré quelques conflits persistants dans le parseur, 
les extensions majeures de syntaxe ont été intégrées et fonctionnent sur des cas d’usage typiques. 
Les conflits restants sont liés à des ambiguïtés difficiles à lever sans refactorisation plus profonde, 
mais n’empêchent pas le fonctionnement du langage.

### Ce que nous n'avons pas réussi à implementer 

Les conflits shift/reduce persistent malgré les tentatives de séparation entre les types d'expressions.

Exemple de code qui pose problème :
```bash
let f x = x - 1;;
```
Peut provoquer un conflit car - est à la fois unaire (dans -1) et binaire (x - 1).

### Conclusion 

La majorité des sucres syntaxiques demandés sont en place et fonctionnels.
Toutefois, la gestion fine des priorités entre appels de fonction et opérateurs binaires 
(notamment SUB) reste source de conflits dans le parseur.
Une approche avec plus de niveaux intermédiaires ou l’utilisation d’un parseur différent
permettrait peut-être de mieux résoudre ces conflits, mais nous ne sommes pas parvenu à le réaliser.

## Typage

### Typage Naive

Lors de la réalisation de cette partie nous avons travailler sur deux fichier en particulier, typer_naive.ml et typer_util.ml

1. Pour ce qui est de l'implémentation de typer_util.ml, nous implémenté cela avec un énorme match with en ayant rajouter en amont un argument de type Counter.t.
Bien sur le fichier type_util.mli a été modifier en conséquence.
De cette façon,  nous avons pu générer de nouvelles variables de type de manière unique à chaque branche de l'analyse syntaxique.

2. Pour ce qui est de l'implémentation de typer_naive.ml, nous avons donc implémenter la fonction type_expr pour faire en sorte de traiter tous les cas.
De cette façon, chaque forme d'expression du langage Mini-ML est correctement analysée et annotée avec un type.

3. Pour illustrer l'implémentation des deux questions précedentes, nous avons décidée de l'illustrer à travers 3,4 exemples:

-  Ce programme teste la capacité du typeur à générer un type générique pour la fonction identité. 
Il montre aussi que l’appel applique ce type correctement. Ca illustre donc :
        * Inférence de type polymorphe : id : 'a -> 'a
        * Application avec plusieurs types : a : int, b : bool
- Définition standard d'une fonction arithmétique, ça illustre:
    * Le typer recupère bien les contraintes et les propoges correctement.
- Ce programme vérifie que le typeur gère les applications partielles.
Il montre aussi que les opérateurs peuvent être passés comme fonctions.
Ca illustre donc :
    * Typage des opérateurs comme fonctions : add : int -> int -> int
    * Application partielle : inc : int -> int
- Ce programme teste la capacité du typeur à gérer une fonction qui prend une fonction
   en argument.
   Il illustre la propagation des contraintes de type dans un contexte complexe.
   Donc ça illustre :
    * application concrète avec une fonction arithmétique.

5. On a choisi d'illustrer notre 3ème programme afin d'illustrer le fonct  du typeur.

On commence avec la définition de add, le type de + est int -> int -> int.
Nous n'avons donc pas de contraintes et le type de add : int->int->int.
En suite on a la définition de inc, qui est une application de add avec 1 en argument.
Ici, add est partiellement appliqué avec l'argument 1, ce qui produit une fonction de type int -> int .
Le type de inc est donc int -> int avec encore une fois aucune contraintes, car add est bien typé et l'application de 1 est correcte.
Enfin, la définition de result qui lui aussi est une application de inc avec le type resultqui est : int
Encore une fois, il n'y aucune contrainte supplémentaire ici non plus, car tout est cohérent avec les types précédement générés.

photo arbre 