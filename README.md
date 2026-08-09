# ladder-build

Tooling that regenerates the 13 `NN-<name>` checkpoint branches of
*Awesome From Scratch* from `main`. This branch shares no history with the
checkpoints or with `main` - it exists so the ladder can always be rebuilt.

- `build.sh` - assembles each chapter tree (slices of main + variants) and
  force-updates the 13 branches. Idempotent: unchanged inputs, identical SHAs.
- `verify.sh` - structural checks: orphan root, strict parent chain,
  `12-lockscreen^{tree} == main^{tree}`, non-variant files byte-identical to
  main, source hygiene greps.
- `chapters.tsv` - branch name + commit title per chapter.
- `chapters/<ch>/manifest` - git pathspecs sliced verbatim from main.
- `chapters/<ch>/overlay.map` - `<dest>\t<variant>` lines.
- `variants/` - per-chapter file variants, shared across chapters.
- `README-template.md` - the checkpoint README stub (chapter 12 ships main's
  README, which is what makes its tree identical to main).

After changing code on main: update any affected variants, run `./build.sh`,
run `./verify.sh`, boot-test the checkpoints, then push the branches.
