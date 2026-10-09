# Exact parameter counts (derived from the model code)

Counted with `sum(p.numel() for p in model.parameters())` on the architectures as instantiated by the campaign drivers.

| Network | Parameters | Rounded | Relative to grid |
| --- | ---: | ---: | ---: |
| Grid arm — HiveNet c96×b8 | 1,443,168 | 1.44 M | +0.0% |
| Graph arm — HiveGraphNet h152×L8 | 1,465,452 | 1.47 M | +1.5% |
| A1 variant — untyped edges | 541,292 | 0.54 M | -62.5% |
| A2 variant — no global pooling | 1,372,732 | 1.37 M | -4.9% |

Graph − grid = 22,284 parameters = +1.54% (the figure +2.1% quoted in earlier documents is the ratio of the rounded millions 1.47/1.44; the exact ratio is +1.5%).
