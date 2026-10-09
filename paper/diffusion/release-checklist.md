# Diffusion checklist (D-035) — every step below is a G-PUBLIC decision of the author

Nothing here is executed by the runtime without an explicit approval of
the specific step. Order follows D-035.

## 0. Before anything leaves the machine

- [ ] Author's full read of `paper/build/report-en.pdf` (157 pp) and
      `report-fr.pdf` (172 pp); corrections, if any, go through the
      sources under `paper/report/` and a rebuild (never the PDFs).
- [ ] Author's read of the short article `paper/short/` (EN + FR) once
      drafted and built (`paper/build/article-{en,fr}.pdf`).
- [ ] Licences: repository MIT (D-005a, `LICENSE` present); third-party
      engines MIT (D-034), not redistributed; Hive rules sheets cited as
      consulted sources only.
- [ ] AI-assistance declaration: present in the report front matter,
      chapter 10 and the article; check the policy of the venue targeted
      (arXiv asks that AI tools are not listed as authors and encourages
      disclosure; workshops and IEEE CoG have their own wording).
- [ ] Nothing personal in the released tree: `grep -rn` for e-mail
      addresses, absolute home paths and tokens over the release tree
      before tagging (the report sources cite `/Users/bechir/...` only
      inside HTML comments that the build strips; the released markdown
      keeps them — decide whether to strip comments in the release copy).

## 1. Repository release (`hive-graph-selfplay`)

- [x] Decide visibility: public at tag `v2.0-report` (done 2026-10-09, D-036) (remote already
      exists, private: `mohamedbechirkefi/hive-graph-selfplay`).
- [ ] Records archive: `bash scripts/make_release_archive.sh` produces
      `release/hive-graph-selfplay-records-v2.0.tar.gz` (evaluation
      records, per-generation clock files, self-play manifests, the final
      and cutoff checkpoints of the ten main runs and the nine ablation
      runs). Expected size ≈ 100–150 MB; attach it to the GitHub release
      rather than committing it. `data/runs/` itself (7.6 GB with
      self-play shards) stays local; the report states what is released.
- [ ] `scripts/reproduce_minimal.sh` must pass against the released
      archive layout (it currently copies from `data/runs/`): adapt the
      script to accept the archive directory, re-run, record in a journal.
- [x] Tag and push only after approval (done 2026-10-09; release with 5 assets): `git tag v2.0-report && git push
      origin main --tags`, then set visibility and upload the archive.

## 2. arXiv preprint

- [ ] Category cs.AI (cross-list cs.LG); first submissions may require an
      endorsement — plan for the delay.
- [ ] Files: `article-en.pdf` as the main document; the full report
      attached as a technical report (second submission or ancillary
      file); French copies linked from the repository (D-006: neither
      language diffused without the other, so both are released in the
      repository the same day).
- [ ] Metadata: title as in the report; single author; abstract 150–200
      words; comments field: "Technical report (157 pp, EN; 172 pp, FR)
      and code at <repository>".
- [ ] Licence on arXiv: CC BY 4.0 recommended for a report meant to be
      cited; the author decides.

## 3. Workshop / conference submission (optional, after the preprint)

- [ ] Candidate venues: a negative-results workshop at NeurIPS, the
      IJCAI Computer Games Workshop, IEEE Conference on Games (full
      conference), ICGA Journal for the long form. Check page limits and
      anonymity rules (an arXiv preprint is compatible with most).
- [ ] If a venue requires an anonymised version, the AI-assistance and
      authorship statements move to the camera-ready.

## 4. LinkedIn post

- [ ] Use `paper/diffusion/linkedin-post.md` (FR or EN), insert the
      arXiv and repository links, post from the author's account.
- [ ] Do not claim beyond the report's perimeter (the drafts already
      state the limits); link to the report rather than quoting numbers
      the reader cannot verify.

## 5. After diffusion

- [ ] Record the published identifiers (arXiv id, DOI if any, release
      tag, post date) in `state/decisions.md` and the claims register's
      front matter; update `paper/report/00-front.md` ("release tag and
      access to be fixed at the time of diffusion") in both languages and
      rebuild.
- [ ] Open H9 (complementary study): freeze protocol v2 (G-FREEZE),
      approve the launch (G-SPEND).
