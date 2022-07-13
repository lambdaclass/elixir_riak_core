:ok = LocalCluster.start()
Application.ensure_all_started(:riax)
ExUnit.start()
