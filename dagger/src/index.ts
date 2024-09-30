import { Container, dag, Directory, func, object } from '@dagger.io/dagger';
import { cpus } from 'os';

@object()
export class Ds {
  @func()
  buildEnv(source: Directory, env = 'test', playwright = false): Container {
    const javascriptCache = dag.cacheVolume('javascript');
    const rubyCache = dag.cacheVolume('bundler');
    const assetsCache = dag.cacheVolume('assets');
    const viteCache = dag.cacheVolume('vite');

    let container = dag
      .container()
      .from('ruby:3.4.2')
      .withDirectory('/ds', source)
      .withMountedCache('/ds/node_modules', javascriptCache)
      .withMountedCache('/usr/local/bundle', rubyCache)
      .withMountedCache('/ds/public/assets', assetsCache)
      .withMountedCache('/ds/public/vite-test', viteCache)
      .withWorkdir('/ds')
      .withEnvVariable('RAILS_ENV', env);

    container = this.withDeps(container);
    if (playwright) {
      container = this.withPlaywright(container);
    }

    //.withExec(['bin/rails', 'assets:precompile'])
    //.withExec(['bin/vite', 'build'])

    return container.withExec(['bun', 'install']).withExec(['bundler']);
  }

  @func()
  async test(source: Directory, spec: string): Promise<string> {
    const container = this.buildEnv(source);

    return this.withPostgres(this.withRedis(container))
      .withExec(['bin/rspec', spec])
      .stdout();
  }

  @func()
  async testAll(source: Directory): Promise<string> {
    const container = this.buildEnv(source);

    const length = cpus().length;
    const runners = Array.from({ length }).map(async (_, index) => {
      return this.withPostgres(
        this.withRedis(container, `redis-${index}`),
        `db-${index}`
      )
        .withNewFile(
          '/ds/run_rspec',
          `#!/bin/bash\nbin/rspec $(split_tests -line-count -exclude-glob='spec/system/**' -split-index=${index} -split-total=${length})`,
          { permissions: 700 }
        )
        .withExec(['./run_rspec'])
        .stdout();
    });
    const outputs = await Promise.all(runners);
    return outputs.join('');
  }

  withPostgres(container: Container, label = 'db'): Container {
    return container
      .withServiceBinding(label, this.postgres(label))
      .withEnvVariable('DATABASE_URL', `postgres://tps_test@${label}/tps_test`)
      .withExec(['bin/rails', 'db:schema:load', 'db:migrate']);
  }

  withRedis(container: Container, label = 'redis'): Container {
    return container
      .withServiceBinding(label, this.redis(label))
      .withEnvVariable('REDIS_CACHE_URL', `redis://${label}`);
  }

  withDeps(container: Container): Container {
    return container
      .withExec(['./bin/install_ci_deps'])
      .withEnvVariable('PATH', '/opt/bin:$PATH', { expand: true });
  }

  withPlaywright(container: Container): Container {
    return container
      .withEnvVariable('PLAYWRIGHT_BROWSERS_PATH', '0')
      .withExec(['bunx', 'playwright', 'install-deps'])
      .withExec(['bunx', 'playwright', 'install', 'chromium']);
  }

  postgres(label = 'db') {
    return dag
      .container()
      .from('postgis/postgis:17-3.5')
      .withLabel('com.dagger.service', label)
      .withEnvVariable('POSTGRES_USER', 'tps_test')
      .withEnvVariable('POSTGRES_PASSWORD', 'tps_test')
      .withEnvVariable('POSTGRES_DB', 'tps_test')
      .asService();
  }

  redis(label = 'redis') {
    return dag
      .container()
      .from('redis')
      .withLabel('com.dagger.service', label)
      .asService();
  }
}
