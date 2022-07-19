import Config

config :riak_core,
  node: 'manager@127.0.0.1',
  web_port: 8198,
  handoff_port: 8199,
  ring_state_dir: 'ring_data_dir_test',
  platform_data_dir: 'data/test' ,
  schema_dirs: ['priv']

config :riax,
  vnode: Riax.VNode.Impl
