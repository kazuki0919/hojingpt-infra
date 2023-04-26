# Cloud Spanner ecosystem's autoscaler porting

- This module is for deploying Cloud Spanner's Autoscaler.
- This was based on `cloudspannerecosystem/autoscaler`'s [30f8d2332930c12ca7a171caaa1701572b34df94](https://github.com/cloudspannerecosystem/autoscaler/tree/30f8d2332930c12ca7a171caaa1701572b34df94).
- In particular, I refer to the [cloud-functions/per-project](https://github.com/cloudspannerecosystem/autoscaler/tree/30f8d2332930c12ca7a171caaa1701572b34df94/terraform/cloud-functions/per-project) section.
- Basically, CloudFunction is ported as is, and terraform is rewritten entirely.
