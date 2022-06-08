import Config

config :riak_core,
  node: 'dev3@127.0.0.1',
  web_port: 8398,
  handoff_port: 8399,
  ring_state_dir: './rings_state/ring_data_dir_1',
  platform_data_dir: '.platform_data/data_1',
  schema_dirs: ['priv']
