# Docker Compose 配置解读: signoz/deploy/docker/docker-compose.yaml

本文档包含了 `signoz/deploy/docker/docker-compose.yaml` 文件的完整内容以及对其详细的分析和解读。

---

## 配置文件内容 (`docker-compose.yaml`)

```yaml
version: "3"
x-common: &common
  networks:
    - signoz-net
  restart: unless-stopped
  logging:
    options:
      max-size: 50m
      max-file: "3"
x-clickhouse-defaults: &clickhouse-defaults
  !!merge <<: *common
  image: clickhouse/clickhouse-server:25.5.6
  tty: true
  labels:
    signoz.io/scrape: "true"
    signoz.io/port: "9363"
    signoz.io/path: "/metrics"
  depends_on:
    init-clickhouse:
      condition: service_completed_successfully
    zookeeper-1:
      condition: service_healthy
  healthcheck:
    test:
      - CMD
      - wget
      - --spider
      - -q
      - 0.0.0.0:8123/ping
    interval: 30s
    timeout: 5s
    retries: 3
  ulimits:
    nproc: 65535
    nofile:
      soft: 262144
      hard: 262144
  environment:
    - CLICKHOUSE_SKIP_USER_SETUP=1
x-zookeeper-defaults: &zookeeper-defaults
  !!merge <<: *common
  image: signoz/zookeeper:3.7.1
  user: root
  labels:
    signoz.io/scrape: "true"
    signoz.io/port: "9141"
    signoz.io/path: "/metrics"
  healthcheck:
    test:
      - CMD-SHELL
      - curl -s -m 2 http://localhost:8080/commands/ruok | grep error | grep null
    interval: 30s
    timeout: 5s
    retries: 3
x-db-depend: &db-depend
  !!merge <<: *common
  depends_on:
    clickhouse:
      condition: service_healthy
    schema-migrator-sync:
      condition: service_completed_successfully
services:
  init-clickhouse:
    !!merge <<: *common
    image: clickhouse/clickhouse-server:25.5.6
    container_name: signoz-init-clickhouse
    command:
      - bash
      - -c
      - |
        version="v0.0.1"
        node_os=$$(uname -s | tr '[:upper:]' '[:lower:]')
        node_arch=$$(uname -m | sed s/aarch64/arm64/ | sed s/x86_64/amd64/)
        echo "Fetching histogram-binary for $${node_os}/$${node_arch}"
        cd /tmp
        wget -O histogram-quantile.tar.gz "https://github.com/SigNoz/signoz/releases/download/histogram-quantile%2F$${version}/histogram-quantile_$${node_os}_$${node_arch}.tar.gz"
        tar -xvzf histogram-quantile.tar.gz
        mv histogram-quantile /var/lib/clickhouse/user_scripts/histogramQuantile
    restart: on-failure
    volumes:
      - ../common/clickhouse/user_scripts:/var/lib/clickhouse/user_scripts/
  zookeeper-1:
    !!merge <<: *zookeeper-defaults
    container_name: signoz-zookeeper-1
    # ports:
    #   - "2181:2181"
    #   - "2888:2888"
    #   - "3888:3888"
    volumes:
      - zookeeper-1:/bitnami/zookeeper
    environment:
      - ZOO_SERVER_ID=1
      - ALLOW_ANONYMOUS_LOGIN=yes
      - ZOO_AUTOPURGE_INTERVAL=1
      - ZOO_ENABLE_PROMETHEUS_METRICS=yes
      - ZOO_PROMETHEUS_METRICS_PORT_NUMBER=9141
  clickhouse:
    !!merge <<: *clickhouse-defaults
    container_name: signoz-clickhouse
    # ports:
    #   - "9000:9000"
    #   - "8123:8123"
    #   - "9181:9181"
    volumes:
      - ../common/clickhouse/config.xml:/etc/clickhouse-server/config.xml
      - ../common/clickhouse/users.xml:/etc/clickhouse-server/users.xml
      - ../common/clickhouse/custom-function.xml:/etc/clickhouse-server/custom-function.xml
      - ../common/clickhouse/user_scripts:/var/lib/clickhouse/user_scripts/
      - ../common/clickhouse/cluster.xml:/etc/clickhouse-server/config.d/cluster.xml
      - clickhouse:/var/lib/clickhouse/
      # - ../common/clickhouse/storage.xml:/etc/clickhouse-server/config.d/storage.xml
  signoz:
    !!merge <<: *db-depend
    image: signoz/signoz:${VERSION:-v0.107.0}
    container_name: signoz
    command:
      - --config=/root/config/prometheus.yml
    ports:
      - "8080:8080" # signoz port
    #   - "6060:6060"     # pprof port
    volumes:
      - ../common/signoz/prometheus.yml:/root/config/prometheus.yml
      - ../common/dashboards:/root/config/dashboards
      - sqlite:/var/lib/signoz/
    environment:
      - SIGNOZ_ALERTMANAGER_PROVIDER=signoz
      - SIGNOZ_TELEMETRYSTORE_CLICKHOUSE_DSN=tcp://clickhouse:9000
      - SIGNOZ_SQLSTORE_SQLITE_PATH=/var/lib/signoz/signoz.db
      - DASHBOARDS_PATH=/root/config/dashboards
      - STORAGE=clickhouse
      - GODEBUG=netdns=go
      - TELEMETRY_ENABLED=true
      - DEPLOYMENT_TYPE=docker-standalone-amd
      - DOT_METRICS_ENABLED=true
    healthcheck:
      test:
        - CMD
        - wget
        - --spider
        - -q
        - localhost:8080/api/v1/health
      interval: 30s
      timeout: 5s
      retries: 3
  otel-collector:
    !!merge <<: *db-depend
    image: signoz/signoz-otel-collector:${OTELCOL_TAG:-v0.129.12}
    container_name: signoz-otel-collector
    command:
      - --config=/etc/otel-collector-config.yaml
      - --manager-config=/etc/manager-config.yaml
      - --copy-path=/var/tmp/collector-config.yaml
      - --feature-gates=-pkg.translator.prometheus.NormalizeName
    volumes:
      - ./otel-collector-config.yaml:/etc/otel-collector-config.yaml
      - ../common/signoz/otel-collector-opamp-config.yaml:/etc/manager-config.yaml
    environment:
      - OTEL_RESOURCE_ATTRIBUTES=host.name=signoz-host,os.type=linux
      - LOW_CARDINAL_EXCEPTION_GROUPING=false
    ports:
      # - "1777:1777"     # pprof extension
      - "4317:4317" # OTLP gRPC receiver
      - "4318:4318" # OTLP HTTP receiver
    depends_on:
      signoz:
        condition: service_healthy
  schema-migrator-sync:
    !!merge <<: *common
    image: signoz/signoz-schema-migrator:${OTELCOL_TAG:-v0.129.12}
    container_name: schema-migrator-sync
    command:
      - sync
      - --dsn=tcp://clickhouse:9000
      - --up=
    depends_on:
      clickhouse:
        condition: service_healthy
    restart: on-failure
  schema-migrator-async:
    !!merge <<: *db-depend
    image: signoz/signoz-schema-migrator:${OTELCOL_TAG:-v0.129.12}
    container_name: schema-migrator-async
    command:
      - async
      - --dsn=tcp://clickhouse:9000
      - --up=
    restart: on-failure
networks:
  signoz-net:
    name: signoz-net
volumes:
  clickhouse:
    name: signoz-clickhouse
  sqlite:
    name: signoz-sqlite
  zookeeper-1:
    name: signoz-zookeeper-1
```

---

## 配置解读

好的，这个 `docker-compose.yaml` 文件是用来定义和运行一个多容器 Docker 应用程序的。具体来说，它部署的是 **SigNoz**，一个开源的可观测性平台，用于监控你的应用程序和基础设施。

对于不熟悉 Docker Compose 的人来说，我们可以把它分解成几个核心部分来理解。

### 整体结构和核心概念

这个配置文件主要由四个顶级部分组成：
1.  `version`: "3" - 指定了 Docker Compose 文件格式的版本。
2.  `x-common`, `x-clickhouse-defaults` 等 - 这些是 **YAML 锚点（Anchors）和别名（Aliases）**，是这个文件中一个非常重要的特性，用于减少重复配置。
3.  `services` - 这是核心部分，定义了组成应用的所有服务（容器）。
4.  `networks` - 定义了服务之间通信所使用的网络。
5.  `volumes` - 定义了用于持久化数据的存储卷。

---

### 1. 重点概念：YAML锚点与别名 (`x-...`)

你会看到很多以 `x-` 开头的块，比如 `x-common`。这是一个 YAML 的高级功能，与 Docker Compose 本身无关，但在这里被巧妙地用来复用配置。

-   **`&common`**: 这部分定义了一个锚点（anchor），名字叫 `common`。它包含了一些所有服务都通用的配置，比如：
    -   `networks: - signoz-net`: 所有服务都连接到 `signoz-net` 这个网络中。
    -   `restart: unless-stopped`: 除非手动停止，否则容器总会自动重启。
    -   `logging`: 配置了日志文件的轮转，防止日志文件过大。

-   **`!!merge <<: *common`**: 在其他服务（如 `clickhouse-defaults`）中，你会看到这一行。`*common` 是对上面 `&common` 锚点的引用（别名），`<<:` 是合并操作。这意味着它会把 `common` 锚点里的所有配置项都复制到当前位置。

这种方式极大地简化了文件，避免了在每个服务下都重复写相同的配置。

---

### 2. 服务 (`services`)

这是应用的主体，定义了需要运行的各个容器。我们来逐个分析：

-   **`init-clickhouse`**:
    -   **作用**: 这是一个初始化容器。它的主要任务是在主数据库 `clickhouse` 启动前，下载一个名为 `histogramQuantile` 的自定义函数二进制文件。
    -   **关键配置**:
        -   `command`: 运行一个 shell 脚本，使用 `wget` 从 GitHub 下载文件。
        -   `restart: on-failure`: 如果任务失败，它会尝试重新运行。
        -   `volumes`: 将主机上的 `./common/clickhouse/user_scripts` 目录挂载到容器中，这样下载的文件就能被 `clickhouse` 服务使用。

-   **`zookeeper-1`**:
    -   **作用**: Zookeeper 是一个分布式协调服务。在这个场景下，它被 ClickHouse 用于集群管理和复制。
    -   **关键配置**:
        -   `healthcheck`: Docker 会定期检查这个服务的健康状况，确保它正常运行后，依赖它的服务才能启动。

-   **`clickhouse`**:
    -   **作用**: 这是 SigNoz 的核心数据存储，一个高性能的列式数据库，用于存储所有的遥测数据（traces, metrics, logs）。
    -   **关键配置**:
        -   `depends_on`: 它依赖 `init-clickhouse` 和 `zookeeper-1`。这意味着 Docker 会确保 Zookeeper 健康且初始化任务成功完成后，再启动 ClickHouse。
        -   `volumes`:
            -   挂载了多个配置文件（`config.xml`, `users.xml` 等），允许你在外部修改 ClickHouse 的配置。
            -   挂载了 `clickhouse` 数据卷，用于持久化存储数据库数据。

-   **`signoz`**:
    -   **作用**: 这是 SigNoz 的后端服务和 Web UI。它负责处理查询请求、触发告警，并提供用户界面。
    -   **关键配置**:
        -   `ports: - "8080:8080"`: 将容器的 8080 端口映射到你主机的 8080 端口。这意味着你可以通过 `http://localhost:8080` 访问 SigNoz UI。
        -   `environment`: 设置了大量的环境变量来配置服务，例如：
            -   `SIGNOZ_TELEMETRYSTORE_CLICKHOUSE_DSN`: 告诉 SigNoz 如何连接到 ClickHouse 数据库。
            -   `STORAGE=clickhouse`: 指定使用 ClickHouse 作为存储。
        -   `depends_on`: 依赖 `clickhouse` 和 `schema-migrator-sync`，确保数据库和表结构准备好之后再启动。

-   **`otel-collector`**:
    -   **作用**: OpenTelemetry Collector（OTel Collector）是一个接收、处理和导出遥测数据的代理。它从你的应用程序接收数据，然后将其发送到 `clickhouse` 数据库。
    -   **关键配置**:
        -   `ports`: 暴露了 `4317` (gRPC) 和 `4318` (HTTP) 端口，这是 OTLP 协议的标准端口，用于接收遥测数据。
        -   `command`: 指定了启动时使用的配置文件。
        -   `volumes`: 挂载了配置文件 `otel-collector-config.yaml`。

-   **`schema-migrator-sync`** 和 **`schema-migrator-async`**:
    -   **作用**: 这两个服务负责管理和迁移 ClickHouse 数据库的表结构（schema）。当 SigNoz 版本更新时，可能需要更新数据库表，这两个服务会自动处理。
    -   `sync` (同步) 任务会阻塞依赖它的服务，直到完成。`async` (异步) 任务则在后台运行。
    -   `restart: on-failure`: 同样，失败后会重试。

---

### 3. 网络 (`networks`)

-   **`signoz-net`**:
    -   定义了一个名为 `signoz-net` 的自定义桥接网络。
    -   所有在这个网络中的服务都可以通过它们的服务名（例如 `clickhouse`, `signoz`）作为主机名直接相互通信。例如，`signoz` 服务可以通过 `tcp://clickhouse:9000` 连接到 `clickhouse` 服务。

---

### 4. 数据卷 (`volumes`)

-   **`clickhouse`, `sqlite`, `zookeeper-1`**:
    -   这里定义了几个 "命名数据卷"（named volumes）。
    -   Docker Compose 会创建并管理这些数据卷，用于持久化存储数据。即使你删除了容器（`docker-compose down`），这些数据卷默认也会被保留，从而防止数据丢失。当你下次启动应用时（`docker-compose up`），容器会重新挂载这些数据卷，恢复之前的状态。

### 总结

这个 `docker-compose.yaml` 文件通过一系列协同工作的服务，完整地部署了一个 SigNoz 实例：

1.  **数据流**: 你的应用发送遥测数据到 `otel-collector`。
2.  **数据处理与存储**: `otel-collector` 处理数据后，将其存入 `clickhouse` 数据库。
3.  **查询与展示**: 你通过浏览器访问 `signoz` 服务的 UI，它会从 `clickhouse` 查询数据并展示出来。
4.  **后台支持**: `zookeeper` 和 `schema-migrator` 等服务确保了整个系统的稳定和正常运行。

通过这个文件，你只需要运行 `docker-compose up -d` 命令，就可以一键启动整个复杂的监控平台，而无需手动配置和启动每一个组件。
