# paper-template

LaTeX academic paper scaffold with versioned draft watermarks, a `build/` directory
for artefacts, and a Makefile-based workflow that works on macOS, Linux, and Windows.

## Quickstart

**Without installing** (run directly from the cloned repo):

```bash
git clone https://github.com/v-i-n-a-y/paper-template
cd paper-template
./new-paper.sh my-paper ~/papers      # creates ~/papers/my-paper/
```

**With install** (`new-paper` available anywhere):

```bash
git clone https://github.com/v-i-n-a-y/paper-template
cd paper-template
./install.sh
new-paper my-paper                    # creates ./my-paper/
new-paper my-paper ~/papers           # creates ~/papers/my-paper/
new-paper --template /custom my-paper # use a different template
```

To remove: `./uninstall.sh`

## Directory layout

```
main.tex          Entry point — submit this file to any journal unchanged
preamble.tex      Shared packages and settings
body.tex          Frontmatter and section includes
references.bib    Bibliography
sections/         One .tex file per section
figures/          TikZ, PGFPlots, or raster figure files
data/             Raw and processed data referenced by figures or text
style/            Journal .cls/.sty/.bst files (LaTeX finds these automatically)
feedback/         Supervisor and reviewer notes
drafts/           Archived draft PDFs with version numbers
.version          Current version as MAJOR.MINOR (managed by make)
.env              Build configuration
new-paper.sh      Scaffold script (not copied into new papers)
install.sh        Install new-paper system-wide
uninstall.sh      Remove the installation
```

## Build targets

```
make              Show help and current version
make config       Show all settings and their current values
make pdf          Build at current version (no version bump)
make draft        Bump minor version, add watermark, archive to drafts/
make bump         Increment major version, reset minor to 0
make set-major N=2   Set major version to 2
make set-minor N=0   Set minor version to 0
make submit       Build without watermark (for submission)
make clean        Remove build/ artefacts
make distclean    Remove build/ and PDF
make pages        Rasterise PDF to page-*.png
make setup        Install LaTeX tools for your platform
make init         Initialise git repo (run once)
```

## Configuration

Edit `.env` or use `make set KEY=... VALUE=...`. Run `make config` to see all values.

| Key | Default | Description |
|---|---|---|
| `PAPER_NAME` | `main` | Output PDF stem (`main.tex` is always the source) |
| `BUILD_DIR` | `build` | Directory for LaTeX artefacts |
| `DRAFTS_DIR` | `drafts` | Where archived draft PDFs are saved |
| `JOBS` | `1` | Parallel make jobs (increase for multi-document builds) |
| `AUTOCLEAN` | `false` | Delete build artefacts after each build |
| `CLEAN_EXTENSIONS` | `aux log …` | Extensions removed by `make clean` |

## Versioning

The `.version` file holds `MAJOR.MINOR`. `make draft` auto-increments the minor
number and saves a copy to `drafts/` named `<PAPER_NAME>-vMAJOR.MINOR.pdf`. Use
`make bump` or `make set-major N=X` when starting a new revision cycle.

The draft watermark is written to `version.tex` at build time and picked up by
`preamble.tex`. `make submit` removes it before building — no source edits needed.

## Journal style files

Drop the journal's `.cls`, `.sty`, `.bst`, and logo PDFs into `style/`. The
Makefile adds `style/` to `TEXINPUTS` and `BSTINPUTS` so `main.tex` can reference
them by filename with no path prefix. For submission, include `style/` in your zip
alongside `main.tex`.

## First-time LaTeX setup

```
make setup    # detects platform and installs via Homebrew / apt / winget
```
