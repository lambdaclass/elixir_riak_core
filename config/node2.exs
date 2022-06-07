import Config

config :riak_core,
  node: 'node2@127.0.0.1',
  web_port: 8199,
  handoff_port: 8186,
  ring_state_dir: 'ring_data_dir_1',
  platform_data_dir: 'data_1'
