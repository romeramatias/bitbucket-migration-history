# Bitbucket Migration History

Migración del historial de contribuciones desde Bitbucket hacia GitHub para reflejar la actividad real en el contribution graph.

## Contexto

Durante varios años y hasta la actualidad, gran parte de mi trabajo profesional estuvo alojado en repositorios privados de Bitbucket. Esto significa que todas esas contribuciones — commits diarios, features, bug fixes, code reviews — no se reflejan en mi perfil de GitHub.

Para representar fielmente esa actividad, cree un bash script que extraiga repo por repo la cantidad de contribuciones realizadas en Bitbucket y las repliqué como commits en este repositorio, respetando las fechas originales.

## Qué contiene este repositorio

Un archivo `contributions.md` que registra cada contribución migrada, organizado por fecha:

```md
# Contribution History

## 2021-05-03
- `09:00:00` migrated from bitbucket
- `09:01:00` migrated from bitbucket
- `09:02:00` migrated from bitbucket

## 2021-05-04
- `09:00:00` migrated from bitbucket
```

Cada commit fue creado con `GIT_AUTHOR_DATE` y `GIT_COMMITTER_DATE` correspondientes a la fecha original de la contribución en Bitbucket, por lo que aparecen correctamente en el contribution graph de GitHub.
