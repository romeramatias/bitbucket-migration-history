# Bitbucket Migration History

This repository reconstructs my historical commit activity from Bitbucket in order to preserve a visible contribution timeline in GitHub.

## Background

A significant portion of my professional work between 2021 and 2026 was done in private Bitbucket repositories belonging to company workspaces.

Because those repositories are private and cannot be publicly mirrored, the contributions made there do not appear in my GitHub activity graph.

To make my public developer profile reflect my actual development activity during that period, I extracted metadata from those repositories and reproduced the commit timestamps in this repository.

This repository therefore represents **a reconstructed timeline of my professional coding activity**, not the original source code.

---

## Activity Summary


Statistics extracted from Bitbucket:

| Metric | Value |
|------|-------|
| Repositories analyzed | 116   |
| Total commits authored | 8121  |
| Unique active days | 1109  |

These commits were authored across multiple internal services and integrations during my work as a backend engineer.

---

## Methodology

A script was written to analyze commit metadata from Bitbucket repositories.

The process:

1. Iterate through repositories in the Bitbucket workspace
2. Extract commits authored by my user
3. Collect commit timestamps
4. Group commits by day
5. Recreate commits in this repository using the original timestamps

Each commit is generated with:
`GIT_AUTHOR_DATE`
`GIT_COMMITTER_DATE` so that the GitHub contribution graph reflects the actual historical timeline.

---

## Repository Contents

The repository includes: `contributions.md` This file records each reconstructed commit grouped by date.

Example:

```md
## 2021-05-03
- 09:00:00 migrated from Bitbucket
- 09:01:00 migrated from Bitbucket
- 09:02:00 migrated from Bitbucket
```

Each entry corresponds to a commit created with random generated timestamp.

## Important Note

This repository does not contain the original source code.

The original repositories belong to private company workspaces and cannot be publicly shared.


## Purpose

The goal of this repository is to provide transparency about my historical coding activity that would otherwise remain invisible due to private repositories.

It allows my GitHub profile to more accurately represent my development history.
