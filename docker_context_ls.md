docker context ls 通过以下方式找到所有的 context：

  主要机制

  1. 扫描配置目录: 读取 ~/.docker/contexts/meta/ 目录下的所有子目录
    - 每个子目录以 context 的哈希值命名（如 f24fd3749c...）
    - 每个子目录包含一个 meta.json 文件，存储 context 的元数据
  2. 读取元数据: 解析每个 meta.json 文件，获取：
    - Name: context 名称
    - Metadata.Description: 描述信息
    - Endpoints.docker.Host: Docker daemon 的连接地址
  3. 添加内置 context:
    - default context 是硬编码的，指向默认的 unix:///var/run/docker.sock
    - 基于当前 DOCKER_HOST 环境变量生成
  4. 标记当前 context: 从 ~/.docker/config.json 的 currentContext 字段读取当前激活的 context，在列表中标记 *

  存储结构

  ~/.docker/
  ├── config.json              # 存储 currentContext
  └── contexts/
      └── meta/
          ├── <hash1>/
          │   └── meta.json    # colima context 配置
          └── <hash2>/
              └── meta.json    # desktop-linux context 配置

