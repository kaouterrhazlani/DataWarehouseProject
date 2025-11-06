# Explication du Code : Extracteur de Données PDF (pdf_extractor.py)

## Vue d'ensemble
Ce script Python extrait automatiquement des informations sur les violations de données (data breaches) à partir de fichiers PDF annuels de l'ITRC (Identity Theft Resource Center). Il parse le contenu des PDF, identifie les données pertinentes, et exporte les résultats dans des fichiers CSV.

## Dépendances
```python
import re            # Module pour les expressions régulières
import pdfplumber    # Bibliothèque pour lire et extraire du texte des fichiers PDF
import pandas as pd  # Bibliothèque pour la manipulation de données et création de DataFrames
```

## Architecture du Code

### 1. Fonctions de Filtrage et Groupement

#### `check_unwanted_keywords_in_the_line(line)`
**Objectif** : Identifier si une ligne contient des mots-clés spécifiques qui servent de séparateurs ou marqueurs.

**Paramètres** :
- `line` (str) : La ligne de texte à analyser

**Retourne** :
- Le mot-clé trouvé ou `None` si aucun mot-clé n'est présent

**Fonctionnement** :
- Définit une liste de mots-clés indésirables : 'Identity Theft', 'Breach List:', 'Records Exposed:', 'Breached Entity:'
- Parcourt chaque mot-clé et utilise `re.search()` pour vérifier sa présence dans la ligne
- Si un mot-clé est trouvé, retourne ce mot-clé

**Exemple** :
```python
line = "Breached Entity: ABC Company"
result = check_unwanted_keywords_in_the_line(line)  # Retourne "Breached Entity:"
```

#### `get_data_lines_from_text(text)`
**Objectif** : Extraire et grouper les lignes de texte qui contiennent des données pertinentes pour l'extraction.

**Paramètres** :
- `text` (str) : Le texte extrait d'une page PDF

**Retourne** :
- `data_lines` (list) : Une liste de groupes de lignes, où chaque groupe représente un enregistrement de violation

**Fonctionnement** :
1. Divise le texte en lignes individuelles avec `text.split('\n')`
2. Pour chaque ligne, vérifie si elle contient un mot-clé indésirable
3. Si aucun mot-clé n'est trouvé (`result is None`), ajoute la ligne au groupe actuel
4. Si le mot-clé "Breached Entity:" est trouvé et qu'un groupe existe, sauvegarde le groupe dans `data_lines` et démarre un nouveau groupe
5. Cette logique permet de segmenter le texte en blocs de données distincts

**Structure des données** :
```
data_lines = [
    [ligne1_bloc1, ligne2_bloc1, ligne3_bloc1],
    [ligne1_bloc2, ligne2_bloc2, ligne3_bloc2],
    ...
]
```

### 2. Fonction Principale d'Extraction

#### `extract_data(data_list)`
**Objectif** : Extraire toutes les informations structurées de chaque bloc de données.

**Paramètres** :
- `data_list` (list) : Liste de blocs de données (chaque bloc est une liste de lignes)

**Retourne** :
- `data` (list) : Liste de listes contenant les données extraites prêtes pour un DataFrame

**Fonctionnement** :
Pour chaque bloc de données :
1. Extrait l'état (state) avec `get_state(block[0])`
2. Extrait la date avec `get_date(block[0])`
3. Extrait le type de violation avec `get_type(block[0])`
4. Extrait la catégorie avec `get_category(block[0])`
5. Extrait le nombre d'enregistrements avec `get_records(block[0])`
6. Combine ces informations pour extraire l'entité violée avec `get_entity()`
7. Extrait la source avec `get_source(block[-2])`
8. Extrait l'URL avec `get_url(block[-1])`
9. Ajoute toutes ces données comme une liste à la liste `data`

**Structure de sortie** :
```python
[
    [entity, state, date, type, category, records, source, url],
    [entity, state, date, type, category, records, source, url],
    ...
]
```

### 3. Décorateur pour la Gestion d'Erreurs

#### `check_data(func)`
**Objectif** : Décorateur qui encapsule les fonctions d'extraction dans un bloc try-except pour gérer les erreurs gracieusement.

**Paramètres** :
- `func` (fonction) : La fonction à décorer

**Retourne** :
- Une fonction wrapper qui gère les exceptions

**Fonctionnement** :
- Définit une fonction interne `inner()` qui exécute la fonction originale dans un bloc `try`
- Si une exception se produit, retourne '-' au lieu de crasher le programme
- Permet au script de continuer même si certaines données sont manquantes ou mal formatées

**Utilisation** :
```python
@check_data
def get_state(line1):
    # Si cette fonction lève une exception, '-' sera retourné
    return re.search(r'\b[A-Z][A-Z]\b', line1).group().strip()
```

### 4. Fonctions d'Extraction Spécifiques

Toutes ces fonctions utilisent le décorateur `@check_data` pour la gestion d'erreurs.

#### `get_records(line1)`
**Objectif** : Extraire le nombre d'enregistrements exposés.

**Méthode** :
- Divise la ligne en mots avec `split(' ')`
- Prend le dernier élément `[-1]`
- Retourne '-' si vide

#### `get_category(line1)`
**Objectif** : Extraire la catégorie de violation.

**Méthode** :
- Divise la ligne en mots
- Prend l'avant-dernier élément `[-2]`

#### `get_type(line1)`
**Objectif** : Identifier le type de violation (papier ou électronique).

**Méthode** :
- Recherche 'Paper Data' dans la ligne → retourne 'Paper Data' si trouvé
- Recherche 'Electronic' dans la ligne → retourne 'Electronic' si trouvé
- Retourne '-' si aucun n'est trouvé

#### `get_date(line1)`
**Objectif** : Extraire la date de publication.

**Méthode** :
- Utilise une expression régulière pour trouver un format de date : `(\d{2}|\d{1})/(\d{2}|\d{1})/\d{4}`
- Ce pattern correspond à : `MM/DD/YYYY` ou `M/D/YYYY`
- Exemple : "12/31/2019" ou "1/5/2019"

#### `get_state(line1)`
**Objectif** : Extraire le code d'état (deux lettres majuscules).

**Méthode** :
- Utilise l'expression régulière `\b[A-Z][A-Z]\b`
- `\b` = limite de mot (word boundary)
- `[A-Z][A-Z]` = exactement deux lettres majuscules
- Exemple : "CA", "NY", "TX"

#### `get_source(line2)`
**Objectif** : Extraire la source de l'information.

**Méthode** :
- Divise la ligne en mots
- Prend le deuxième élément `[1]` (index 1)
- Retourne '-' si vide

#### `get_url(line3)`
**Objectif** : Extraire l'URL associée.

**Méthode** :
- Divise la ligne en mots
- Prend le deuxième élément `[1]`
- Retourne '-' si vide

#### `get_entity(block, extracted_text)`
**Objectif** : Extraire le nom de l'entité violée.

**Méthode** :
1. Supprime le texte déjà extrait de la première ligne avec `re.sub(extracted_text, '', block[0])`
2. Si le bloc contient plus de 3 lignes, concatène les lignes du milieu (entre la première et les deux dernières)
3. Nettoie le résultat en supprimant les doubles espaces et guillemets
4. Retourne '-' en cas d'erreur

**Pourquoi cette approche ?** :
Certaines entités ont des noms longs qui s'étendent sur plusieurs lignes. Cette fonction reconstitue le nom complet.

### 5. Fonctions Utilitaires

#### `file_list()`
**Objectif** : Fournir la liste des fichiers PDF à traiter.

**Retourne** :
```python
['script/ITRCAnnualReportPdf2019.pdf',
 'script/ITRCAnnualReportPdf2018.pdf']
```

**Note** : Les fichiers doivent être dans le même dossier que le script.

#### `create_dataframe()`
**Objectif** : Créer un DataFrame Pandas avec les colonnes appropriées.

**Colonnes** :
- `BreachedEntity` : Nom de l'entité violée
- `State` : Code d'état (2 lettres)
- `PublishedDate` : Date de publication
- `BreachType` : Type de violation (Paper Data / Electronic)
- `BreachCategory` : Catégorie de violation
- `RecorsReported` : Nombre d'enregistrements exposés (Note : typo dans le nom de colonne - "Recors" au lieu de "Records")
- `Source` : Source de l'information
- `URL` : Lien vers plus d'informations

### 6. Point d'Entrée Principal (`if __name__ == "__main__":`)

**Workflow complet** :

```python
df = create_dataframe()  # Crée un DataFrame vide avec les colonnes appropriées

for file in file_list():  # Pour chaque fichier PDF
    with pdfplumber.open(file) as pdf:  # Ouvre le PDF
        pages = pdf.pages  # Récupère toutes les pages
        for page in pages:  # Pour chaque page
            text = page.extract_text()  # Extrait le texte
            data_lines = get_data_lines_from_text(text)  # Groupe les lignes de données
            data = extract_data(data_lines)  # Extrait les données structurées
            df = df.append(pd.DataFrame(data, columns=df.columns))  # Ajoute au DataFrame
            print(f'EXTRACTED: page {page.page_number} of {file}')  # Log de progression

    df.to_csv(f'{file[:-4]}.csv', index=False, sep=';')  # Exporte en CSV
    print('Data successfully extracted and saved to csv file!...')
```

**Étapes détaillées** :

1. **Initialisation** : Crée un DataFrame vide
2. **Itération sur les fichiers** : Parcourt chaque fichier PDF
3. **Ouverture du PDF** : Utilise `pdfplumber.open()` dans un contexte manager
4. **Traitement page par page** :
   - Extrait le texte brut de la page
   - Groupe les lignes en blocs de données
   - Extrait les informations de chaque bloc
   - Ajoute les données au DataFrame
   - Affiche la progression
5. **Export** : Sauvegarde le DataFrame en CSV avec `;` comme séparateur
6. **Confirmation** : Affiche un message de succès

## Format du Fichier CSV de Sortie

Le fichier CSV généré aura la structure suivante :

```csv
BreachedEntity;State;PublishedDate;BreachType;BreachCategory;RecorsReported;Source;URL
ABC Company;CA;01/15/2019;Electronic;Hacking;50000;Website;http://example.com
XYZ Corp;NY;03/22/2019;Paper Data;Theft;1200;News;http://example2.com
```

## Flux de Données

```
Fichiers PDF
    ↓
[pdfplumber] Extraction du texte brut
    ↓
[get_data_lines_from_text] Groupement en blocs de données
    ↓
[extract_data] Extraction des champs individuels
    ↓
[DataFrame Pandas] Agrégation des données
    ↓
Fichiers CSV
```

## Points Techniques Importants

### Expressions Régulières Utilisées

1. **Date** : `(\d{2}|\d{1})/(\d{2}|\d{1})/\d{4}`
   - Accepte 1 ou 2 chiffres pour le mois
   - Accepte 1 ou 2 chiffres pour le jour
   - Exige 4 chiffres pour l'année

2. **État** : `\b[A-Z][A-Z]\b`
   - Exactement 2 lettres majuscules
   - Entourées de limites de mots

3. **Recherche de mots-clés** : `re.search(keyword, line)`
   - Recherche simple de sous-chaîne

### Gestion des Erreurs

- Toutes les fonctions d'extraction sont protégées par le décorateur `@check_data`
- En cas d'erreur, retourne '-' au lieu de crasher
- Permet de gérer des formats de données inconsistants

### Optimisations Possibles

1. **Performance** : Remplacer `df.append()` par une liste puis créer le DataFrame à la fin (append est déprécié)
2. **Validation** : Ajouter des validations sur les formats de données extraites
3. **Configuration** : Externaliser les chemins de fichiers dans un fichier de configuration
4. **Logging** : Utiliser le module `logging` au lieu de `print()`
5. **Tests** : Ajouter des tests unitaires pour chaque fonction d'extraction

## Cas d'Usage

Ce script est particulièrement utile pour :
- Automatiser l'extraction de rapports PDF structurés
- Convertir des données PDF en format tabulaire (CSV)
- Analyser des tendances dans les violations de données
- Alimenter une base de données ou un data warehouse avec des données historiques
- Créer des rapports ou visualisations à partir de données PDF

## Limitations

1. **Format spécifique** : Le script est conçu pour un format PDF très spécifique (rapports ITRC)
2. **Robustesse** : Peut échouer si la structure du PDF change
3. **Typo** : Nom de colonne "RecorsReported" au lieu de "RecordsReported"
4. **Méthode dépréciée** : `df.append()` est déprécié dans pandas récent

## Conclusion

Ce script démontre une approche efficace pour extraire des données structurées de fichiers PDF. Il utilise des techniques de parsing de texte, expressions régulières, et manipulation de données avec Pandas pour transformer des PDF non structurés en données tabulaires utilisables pour l'analyse.
