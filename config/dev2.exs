import Config

config :riak_core,
  node: 'dev2@127.0.0.1',
  web_port: 8298,
  handoff_port: 8299,
  ring_state_dir: './rings_state/ring_data_dir_2',
  platform_data_dir: '.platform_data/data_2',
  schema_dirs: ['priv']
