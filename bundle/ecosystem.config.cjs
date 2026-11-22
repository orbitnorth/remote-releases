module.exports = {
  apps: [
    {
      name: 'remote',
      script: 'server.mjs',
      cwd: __dirname,
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      env: {
        NODE_ENV: 'production',
        REMOTE_AUTO_START: '1',
        PORT: process.env.PORT || 7682,
        HOST: process.env.HOST || '0.0.0.0',
        REMOTE_DATA_DIR: process.env.REMOTE_DATA_DIR || './data',
      },
    },
  ],
};
