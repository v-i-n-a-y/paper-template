# LaTeX Repo Template

Create a new paper from this template using the script at the repo root:

```
./new-paper.sh my-paper-name
cd my-paper-name
```

## Directory layout

```
main.tex          Entry point — submit this file to any journal unchanged
preamble.tex      Shared packages and settings
body.tex          Frontmatter and section includes
references.bib    Bibliography
sections/         One .tex file per section
figures/          TikZ, PGFPlots, or raster figure files
data/             Raw data and processed outputs referenced by figures or text
style/            Journal .cls/.sty/.bst files (LaTeX finds these automatically)
feedback/         Supervisor and reviewer notes
drafts/           Archived draft PDFs with version numbers
VERSION           Current version as MAJOR.MINOR
.env              Build configuration (paper name, autoclean, etc.)
```

## Build

```
make              Show help and current version
make pdf          Build at current version (no version bump)
make draft        Bump minor version, add watermark, archive to drafts/
make bump         Increment major version, reset minor to 0
make submit       Build without watermark for submission
make clean        Remove build artefacts
make setup        Install LaTeX tools for your platform
```

## Versioning

The `VERSION` file holds `MAJOR.MINOR`. Running `make draft` increments the minor
number automatically and saves a copy to `drafts/` named with the version (e.g.
`my-paper-v1.3.pdf`). Use `make bump` when starting a new revision cycle; the
major number is yours to control.

The draft watermark is written to `version.tex` at build time and read by
`preamble.tex`. It is not committed to git. Running `make submit` removes it
before building, so the submission PDF is always clean.

## Journal style files

Drop the journal's `.cls`, `.sty`, `.bst`, and any logo PDFs into `style/`.
The Makefile adds `style/` to `TEXINPUTS` and `BSTINPUTS`, so `main.tex` can
reference them by filename with no path prefix. For submission, include the
`style/` directory alongside `main.tex` in your zip.

## First-time setup

If LaTeX is not installed, run `make setup` — it detects your platform and
installs the required packages via Homebrew (macOS), apt (Linux), or gives
winget instructions (Windows).
