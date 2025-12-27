# 在业务层和基础设施层之间：错误处理与日志记录的分层原则

> 代码片段（Redis `HMGet`）：
> ```go
> func HMGet(ctx context.Context, key string, fields []string)  (any, error) {
>   fullKey := "xxxxxxxxxxx"
>   fields := []string{f1, f2, f3}
>
>   result, err := redisClient.HMGet(ctx, fullKey, fields...).Result()
>   if err != nil {
>     log.ErrorContextf(ctx, "hmget failed. key: %s, err: %v", fullKey, err)
>     return nil, err
>   }
>   ...
> }
> ```
>  
> 这里的疑问是：  
> *是* 在 **内部** 打印日志更合适，还是 **返回包装好的错误** 让调用方自行打印？

本文给出一个 **分层** 的错误与日志处理思路，帮助你在实际项目中做出更清晰、更易维护的决策。

---

## 1️⃣ 业务场景快速回顾

- **基础设施层**：Redis、数据库、第三方 SDK 等，负责与外部系统的交互。
- **业务/服务层**：业务逻辑、HTTP 处理器、命令/查询处理器等，负责实现业务需求。
- **工具/通用库**：可复用的代码段、工具函数，供多项目使用。

---

## 2️⃣ 错误与日志的职责拆分

| 层次 | 负责什么 | 不能做什么 |
|------|----------|------------|
| **基础设施层** | 只负责执行操作、返回错误 | 打印业务级日志 |
| **业务层** | 记录错误、统一日志格式 | 随意包装错误（除非需要保留更多上下文） |
| **工具层** | 只返回错误，必要时做重试 | 打印日志 |

> **核心原则**：  
> **“谁知道错误最有意义？”**——  
> 业务层最清楚业务语义，基础设施层最清楚技术细节。

---

## 3️⃣ 具体实现示例

### 3.1 业务层（HTTP Handler）

```go
func (h *Handler) GetVoiceData(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context()
    key := chi.URLParam(r, "key")

    data, err := h.client.GetVoiceData(ctx, key)
    if err != nil {
        // 统一日志格式，结构化字段方便后续分析
        h.logger.ErrorContextf(ctx,
            "failed to get voice data",
            zap.String("key", key),
            zap.Error(err),
        )
        http.Error(w, "internal error", http.StatusInternalServerError)
        return
    }

    writeJSON(w, data)
}
```

- **日志**：在业务层捕获错误后，统一打印。
- **错误**：业务层不需要额外包装（除非业务特定信息），直接传递。

---

### 3.2 基础设施层（Redis Wrapper）

```go
func (c *Client) GetVoiceData(ctx context.Context, key string) (*VoiceData, error) {
    fullKey := fmt.Sprintf("%s:%s:%s", KeyPrefix, c.env, key)
    fields := []string{
        constant.RedisVoiceDataFieldFileID,
        constant.RedisVoiceDataFieldAudioMD5,
    }

    result, err := c.redisClient.Client.HMGet(ctx, fullKey, fields...).Result()
    if err != nil {
        // 只做错误包装，保留原始错误
        return nil, fmt.Errorf("HMGet failed (key=%s): %w", fullKey, err)
    }

    data, parseErr := parseVoiceData(result)
    if parseErr != nil {
        return nil, fmt.Errorf("parse voice data failed: %w", parseErr)
    }

    return data, nil
}
```

- **错误包装**：使用 `%w` 保留错误链，方便 `errors.Is/As` 检查。
- **日志**：**不打印**，让调用方决定何时记录。

---

### 3.3 可选：内部日志（重试、慢查询等）

如果业务需要在内部层记录重试或性能异常，可通过可配置的日志接口：

```go
type Logger interface {
    Debugf(format string, args ...interface{})
    Infof(format string, args ...interface{})
    Errorf(format string, args ...interface{})
}

func (c *Client) GetVoiceData(ctx context.Context, key string, lg Logger) (*VoiceData, error) {
    // ...
    if err != nil {
        if lg != nil {
            lg.Errorf("HMGet failed (key=%s): %v", fullKey, err)
        }
        return nil, fmt.Errorf("HMGet failed (key=%s): %w", fullKey, err)
    }
    // ...
}
```

调用方可以传入真正的日志实现，或一个空实现来关闭日志。

---

## 4️⃣ 何时在内部层打印日志？

| 场景 | 是否打印日志 | 说明 |
|------|--------------|------|
| **异常重试** | ✅ | 记录重试次数、失败原因 |
| **性能监控（慢查询）** | ✅ | 记录耗时超过阈值的请求 |
| **调试信息（开发/测试）** | ✅ | 通过日志级别控制，仅在非正式环境下打开 |
| **业务错误** | ❌ | 业务层负责 |

> 只在**需要**记录内部细节时，且日志信息对业务无直接意义时才考虑在内部层打印。

---

## 5️⃣ 结论 & 最佳实践

| 步骤 | 做什么 | 备注 |
|------|--------|------|
| 1️⃣ 把错误包装后返回 | 维护错误链，保留原始错误 | 业务层可根据需要进一步包装 |
| 2️⃣ 在业务层统一打印日志 | 结构化、统一的日志格式 | 方便监控、报警、排查 |
| 3️⃣ 只在特殊情况（重试、慢查询）内部打印日志 | 通过可配置接口 | 需注意避免日志冗余 |
| 4️⃣ 让层次职责分明 | 代码可维护、易扩展 | 减少耦合、提高复用率 |

> **一句话总结**：  
> **“基础设施层返回错误，业务层负责日志。”**  
> 这样既能保持错误信息完整，又能避免日志重复与层次混乱。

---

> 💡 **小贴士**  
> - 使用 `zap`, `logrus`, `zerolog` 等结构化日志库，可让日志更易于搜索与聚合。  
> - 在测试环境下开启更细粒度的日志（`Debug`/`Trace`），正式环境保持 `Info`/`Error`。  

祝编码愉快 🚀
