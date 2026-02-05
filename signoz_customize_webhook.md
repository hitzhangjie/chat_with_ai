signoz支持metric-based,log-based,traces-based alert，配置alert时支持配置多种channel，比如slack、email、webhook、microsoft teams以及其他channels。

当然其中最通用的方式就是自定义webhook，我们可以自己实现一个http服务，实现一个http endpoint作为webhook地址，然后对接收到的alert请求进行各种自定义逻辑。

这里我们实现一个自定义http服务，提供一个webhook地址，然后在signoz的alert channels中进行配置：

### webhook

1. 首先实现一个http服务，接受signoz alert通知，这个项目地址放置在了：https://github.com/dist-sys-dev/signoz-webhook，并且提供dockerfile方便进行镜像构建、容器编排；
2. 同时呢为了让signoz这个服务能够访问咱们这个自定义的服务，我们希望将signoz-webhook、signoz共享网络signoz-net，所以要修改dist-sys-dev/signoz/deploy/docker/docker-compose.yaml；
3. 然后docker compose up -d启动signoz相关的所有容器，以及咱们自定义的这个接收alert的http服务；
4. 为了在signoz中配置webhook形式的alert channel，我们需要知道这个signoz-webhook容器的ip地址信息，`docker login -it <containerid> /bin/sh` 然后执行 `ifconfig`，确定了容器地址后，就可以回到signoz alert channel配置面板进行配置：http://172.0.1.3:9999，然后执行测试通过。
5. 之后我们就可以通过webui进行测试，我这里是提前配置了一个CreateBooks数量的dashboard，并在这个dashboard基础上配置alert，如5min内超过5次创建就触发alert，这里的alert channel配置为前面的webhook地址。
6. 我们可以通过 `docker logs -f signoz-webhook` 来观察咱们这个自定义容器的输出，下面这个就是收到的signoz发送来的告警通知：

--- Formatted JSON ---
{
  "alerts": [
    {
      "annotations": {
        "description": "This alert is fired when the defined metric (current value: 14) crosses the threshold (5)",
        "related_logs": "http://localhost:8080/logs/logs-explorer?compositeQuery=%257B%2522queryType%2522%253A%2522builder%2522%252C%2522builder%2522%253A%257B%2522queryData%2522%253A%255B%257B%2522queryName%2522%253A%2522A%2522%252C%2522stepInterval%2522%253A60%252C%2522dataSource%2522%253A%2522logs%2522%252C%2522aggregateOperator%2522%253A%2522noop%2522%252C%2522aggregateAttribute%2522%253A%257B%2522key%2522%253A%2522%2522%252C%2522dataType%2522%253A%2522%2522%252C%2522type%2522%253A%2522%2522%252C%2522isColumn%2522%253Afalse%252C%2522isJSON%2522%253Afalse%257D%252C%2522expression%2522%253A%2522A%2522%252C%2522disabled%2522%253Afalse%252C%2522limit%2522%253A0%252C%2522offset%2522%253A0%252C%2522pageSize%2522%253A0%252C%2522ShiftBy%2522%253A0%252C%2522IsAnomaly%2522%253Afalse%252C%2522QueriesUsedInFormula%2522%253Anull%252C%2522filter%2522%253A%257B%2522expression%2522%253A%2522http.method%253D%2527POST%2527%2522%257D%257D%255D%252C%2522queryFormulas%2522%253A%255B%255D%257D%257D\u0026timeRange=%7B%22start%22%3A1770308820000%2C%22end%22%3A1770309120000%2C%22pageSize%22%3A100%7D\u0026startTime=1770308820000\u0026endTime=1770309120000\u0026options=%7B%22maxLines%22%3A0%2C%22format%22%3A%22%22%2C%22selectColumns%22%3Anull%7D",
        "summary": "The rule threshold is set to 5, and the observed metric value is 14"
      },
      "endsAt": "0001-01-01T00:00:00Z",
      "fingerprint": "f6b6482267d0cf64",
      "generatorURL": "http://localhost:8080/alerts/edit?ruleId=019c2e1e-f7ee-7a7a-ab66-ebeb03e90d26",
      "labels": {
        "alertname": "CreateTooManyBooks",
        "http.method": "POST",
        "ruleId": "019c2e1e-f7ee-7a7a-ab66-ebeb03e90d26",
        "ruleSource": "http://localhost:8080/alerts/edit?ruleId=019c2e1e-f7ee-7a7a-ab66-ebeb03e90d26",
        "severity": "warning",
        "threshold.name": "warning"
      },
      "startsAt": "2026-02-05T16:30:57.467985072Z",
      "status": "firing"
    }
  ],
  "commonAnnotations": {
    "description": "This alert is fired when the defined metric (current value: 14) crosses the threshold (5)",
    "related_logs": "http://localhost:8080/logs/logs-explorer?compositeQuery=%257B%2522queryType%2522%253A%2522builder%2522%252C%2522builder%2522%253A%257B%2522queryData%2522%253A%255B%257B%2522queryName%2522%253A%2522A%2522%252C%2522stepInterval%2522%253A60%252C%2522dataSource%2522%253A%2522logs%2522%252C%2522aggregateOperator%2522%253A%2522noop%2522%252C%2522aggregateAttribute%2522%253A%257B%2522key%2522%253A%2522%2522%252C%2522dataType%2522%253A%2522%2522%252C%2522type%2522%253A%2522%2522%252C%2522isColumn%2522%253Afalse%252C%2522isJSON%2522%253Afalse%257D%252C%2522expression%2522%253A%2522A%2522%252C%2522disabled%2522%253Afalse%252C%2522limit%2522%253A0%252C%2522offset%2522%253A0%252C%2522pageSize%2522%253A0%252C%2522ShiftBy%2522%253A0%252C%2522IsAnomaly%2522%253Afalse%252C%2522QueriesUsedInFormula%2522%253Anull%252C%2522filter%2522%253A%257B%2522expression%2522%253A%2522http.method%253D%2527POST%2527%2522%257D%257D%255D%252C%2522queryFormulas%2522%253A%255B%255D%257D%257D\u0026timeRange=%7B%22start%22%3A1770308820000%2C%22end%22%3A1770309120000%2C%22pageSize%22%3A100%7D\u0026startTime=1770308820000\u0026endTime=1770309120000\u0026options=%7B%22maxLines%22%3A0%2C%22format%22%3A%22%22%2C%22selectColumns%22%3Anull%7D",
    "summary": "The rule threshold is set to 5, and the observed metric value is 14"
  },
  "commonLabels": {
    "alertname": "CreateTooManyBooks",
    "http.method": "POST",
    "ruleId": "019c2e1e-f7ee-7a7a-ab66-ebeb03e90d26",
    "ruleSource": "http://localhost:8080/alerts/edit?ruleId=019c2e1e-f7ee-7a7a-ab66-ebeb03e90d26",
    "severity": "warning",
    "threshold.name": "warning"
  },
  "externalURL": "http://localhost:8080",
  "groupKey": "{__receiver__=\"MyWebHook\"}:{ruleId=\"019c2e1e-f7ee-7a7a-ab66-ebeb03e90d26\"}",
  "groupLabels": {
    "ruleId": "019c2e1e-f7ee-7a7a-ab66-ebeb03e90d26"
  },
  "receiver": "MyWebHook",
  "status": "firing",
  "truncatedAlerts": 0,
  "version": "4"
}
----------------------
