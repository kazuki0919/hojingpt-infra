# CloudSpannerEcosystem/Autoscaler
このモジュールは、Cloud Spanner の Autoscaler をデプロイするためのモジュールで `cloudspannerecosystem/autoscaler` の [30f8d2332930c12ca7a171caaa1701572b34df94](https://github.com/cloudspannerecosystem/autoscaler/tree/30f8d2332930c12ca7a171caaa1701572b34df94) をもとに作られました。特に [cloud-functions/per-project](https://github.com/cloudspannerecosystem/autoscaler/tree/30f8d2332930c12ca7a171caaa1701572b34df94/terraform/cloud-functions/per-project) の部分を参考にしています。基本的に CloudFunction はそのままの内容を移植し、terraform はすべて書き直しています。