<!-- Rows to append to the study-design table (tbl:f-design) of Appendix F when the second-study chapter is merged. -->

| Term | Definition | French equivalent |
| --- | --- | --- |
| warm start | Initialising the network of generation $g$ from the weights of generation $g-1$'s final checkpoint, with the optimizer and the schedule restarted; used in the second study only, the first study re-initialised every generation. | démarrage à chaud |
| replay window | The recent generations whose records a generation trains on; 3 generations in the second study, the current generation alone in the first. | fenêtre de rejeu |
| equal-time cutoff of the second study | The median total training wall-clock of the five grid runs of the second study, computed once from the clock files before any cross-arm number; a value of its own, distinct from the first study's 18.77 h. | seuil à temps mural égal de la seconde étude\* |
| second study | The separately pre-registered comparison under warm start and replay window (protocol version 2.0, frozen 13 October 2026, seeds 11 to 15); reported beside the first study, never pooled with it. | seconde étude |
<!-- src: docs/protocol-v2.md:3-12, 53-60, 105-120 -->
