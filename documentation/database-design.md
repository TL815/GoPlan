# GoPlan 数据库设计文档

> 版本 v1.0 | 数据库：PostgreSQL 16

## 1. 设计原则

- 主键统一使用 UUID v7（时间有序，避免自增ID暴露业务量）
- 所有表包含 `created_at` 和 `updated_at` 时间戳
- 软删除使用 `deleted_at` 字段
- 地理坐标使用 PostGIS `geometry(Point, 4326)` 类型
- JSON字段用于灵活的扩展属性（如AI生成元数据）
- 行程数据支持实时协作，使用乐观锁（version字段）

## 2. ER图（核心实体关系）

```
users ──1:N── plans ──1:N── plan_days ──1:N── plan_pois
  │               │
  │               └──1:N── plan_members (协作关系)
  │
  └──1:N── bookmarks
  │
  └──1:N── inspirations
```

## 3. 建表语句

### 3.1 用户表

```sql
CREATE TABLE users (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone       VARCHAR(20) NOT NULL UNIQUE,
    nickname    VARCHAR(50) NOT NULL DEFAULT '旅行者',
    avatar_url  TEXT,
    bio         VARCHAR(200),
    travel_count INT NOT NULL DEFAULT 0,
    plan_count  INT NOT NULL DEFAULT 0,
    last_login_at TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at  TIMESTAMPTZ
);

CREATE INDEX idx_users_phone ON users(phone) WHERE deleted_at IS NULL;
```

### 3.2 验证码表

```sql
CREATE TABLE verification_codes (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone       VARCHAR(20) NOT NULL,
    code        VARCHAR(10) NOT NULL,
    used        BOOLEAN NOT NULL DEFAULT false,
    expires_at  TIMESTAMPTZ NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_vcodes_phone ON verification_codes(phone, created_at DESC);
```

### 3.3 行程表

```sql
CREATE TABLE plans (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id      UUID NOT NULL REFERENCES users(id),
    title         VARCHAR(100) NOT NULL,
    destination   VARCHAR(100),
    cover_url     TEXT,
    start_date    DATE,
    end_date      DATE,
    accent_color  VARCHAR(9) DEFAULT '#28D99A',
    status        VARCHAR(20) NOT NULL DEFAULT 'planning'
                    CHECK (status IN ('planning','ongoing','completed','archived')),
    ai_session_id UUID,           -- 关联AI生成会话
    version       INT NOT NULL DEFAULT 1,  -- 乐观锁
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at    TIMESTAMPTZ
);

CREATE INDEX idx_plans_owner ON plans(owner_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_plans_status ON plans(status) WHERE deleted_at IS NULL;
```

### 3.4 行程协作成员表

```sql
CREATE TABLE plan_members (
    id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id   UUID NOT NULL REFERENCES plans(id) ON DELETE CASCADE,
    user_id   UUID NOT NULL REFERENCES users(id),
    role      VARCHAR(20) NOT NULL DEFAULT 'editor'
                CHECK (role IN ('owner','editor','viewer')),
    joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(plan_id, user_id)
);

CREATE INDEX idx_plan_members_plan ON plan_members(plan_id);
CREATE INDEX idx_plan_members_user ON plan_members(user_id);
```

### 3.5 行程日表

```sql
CREATE TABLE plan_days (
    id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id   UUID NOT NULL REFERENCES plans(id) ON DELETE CASCADE,
    day_num   INT NOT NULL,
    date      DATE,
    theme     VARCHAR(100),
    weather   JSONB,            -- { temp_high, temp_low, condition }
    note      TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(plan_id, day_num)
);

CREATE INDEX idx_plan_days_plan ON plan_days(plan_id);
```

### 3.6 行程POI表

```sql
CREATE TABLE plan_pois (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_day_id     UUID NOT NULL REFERENCES plan_days(id) ON DELETE CASCADE,
    plan_id         UUID NOT NULL REFERENCES plans(id) ON DELETE CASCADE,
    poi_ref_id      UUID REFERENCES pois(id),       -- 关联POI主表（可为空，支持自定义地点）
    name            VARCHAR(100) NOT NULL,
    category        VARCHAR(20) NOT NULL
                      CHECK (category IN ('scenic','food','hotel','shopping','transport','other')),
    location        geometry(Point, 4326),
    latitude        DOUBLE PRECISION NOT NULL,
    longitude       DOUBLE PRECISION NOT NULL,
    sort_order      INT NOT NULL DEFAULT 0,
    start_time      TIME,
    duration_min    INT DEFAULT 0,      -- 预计停留时间（分钟）
    note            TEXT,
    ai_suggestion   TEXT,               -- AI对此POI的建议
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_plan_pois_day ON plan_pois(plan_day_id);
CREATE INDEX idx_plan_pois_plan ON plan_pois(plan_id);
CREATE INDEX idx_plan_pois_location ON plan_pois USING GIST(location);
```

### 3.7 POI主表（共享POI库）

```sql
CREATE TABLE pois (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        VARCHAR(200) NOT NULL,
    category    VARCHAR(20) NOT NULL
                  CHECK (category IN ('scenic','food','hotel','shopping','transport','other')),
    location    geometry(Point, 4326) NOT NULL,
    latitude    DOUBLE PRECISION NOT NULL,
    longitude   DOUBLE PRECISION NOT NULL,
    address     VARCHAR(500),
    city        VARCHAR(50),
    province    VARCHAR(50),
    amap_id     VARCHAR(50),           -- 高德POI ID
    photos      JSONB DEFAULT '[]',    -- [url1, url2, ...]
    rating      DECIMAL(2,1),
    price_level INT,                   -- 1-4 价位等级
    open_time   VARCHAR(50),
    metadata    JSONB DEFAULT '{}',    -- 扩展信息
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_pois_category ON pois(category);
CREATE INDEX idx_pois_location ON pois USING GIST(location);
CREATE INDEX idx_pois_city ON pois(city);
```

### 3.8 AI对话会话表

```sql
CREATE TABLE ai_sessions (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id),
    plan_id     UUID REFERENCES plans(id),  -- 生成后关联的行程
    status      VARCHAR(20) NOT NULL DEFAULT 'active'
                  CHECK (status IN ('active','completed','failed')),
    messages    JSONB NOT NULL DEFAULT '[]',  -- [{role, content, timestamp}, ...]
    result_json JSONB,                        -- AI生成的原始行程JSON
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_ai_sessions_user ON ai_sessions(user_id, created_at DESC);
```

### 3.9 旅行灵感Feed表

```sql
CREATE TABLE inspirations (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title       VARCHAR(200) NOT NULL,
    description TEXT,
    cover_url   TEXT NOT NULL,
    destination VARCHAR(100),
    category    VARCHAR(30) NOT NULL DEFAULT 'destination'
                  CHECK (category IN ('destination','food','photo','hidden_gem')),
    tags        JSONB DEFAULT '[]',
    author_name VARCHAR(50),
    author_avatar TEXT,
    like_count  INT NOT NULL DEFAULT 0,
    view_count  INT NOT NULL DEFAULT 0,
    is_featured BOOLEAN NOT NULL DEFAULT false,
    published_at TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at  TIMESTAMPTZ
);

CREATE INDEX idx_inspirations_category ON inspirations(category) WHERE deleted_at IS NULL AND published_at IS NOT NULL;
CREATE INDEX idx_inspirations_featured ON inspirations(is_featured, published_at DESC) WHERE deleted_at IS NULL;
```

### 3.10 收藏表

```sql
CREATE TABLE bookmarks (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id),
    bookmark_type   VARCHAR(20) NOT NULL CHECK (bookmark_type IN ('inspiration','plan','poi')),
    target_id       UUID NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(user_id, bookmark_type, target_id)
);

CREATE INDEX idx_bookmarks_user ON bookmarks(user_id, created_at DESC);
```

### 3.11 操作日志表（协作冲突追踪）

```sql
CREATE TABLE plan_operation_logs (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id     UUID NOT NULL REFERENCES plans(id) ON DELETE CASCADE,
    user_id     UUID NOT NULL REFERENCES users(id),
    action      VARCHAR(50) NOT NULL,   -- poi_added, poi_removed, poi_moved, plan_updated
    target      VARCHAR(50),             -- 操作目标类型
    target_id   UUID,                    -- 操作目标ID
    changes     JSONB NOT NULL DEFAULT '{}',
    version     INT NOT NULL,            -- 操作时的plan.version
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_plan_op_logs ON plan_operation_logs(plan_id, created_at DESC);
```

---

## 4. 实体关系说明

| 关系 | 类型 | 说明 |
|------|------|------|
| users → plans | 1:N | 一个用户可创建多个行程 |
| plans → plan_members | 1:N | 一个行程可有多个协作成员 |
| plans → plan_days | 1:N | 一个行程包含多天 |
| plan_days → plan_pois | 1:N | 一天包含多个POI |
| plan_pois → pois | N:1 (可选) | POI可关联共享POI库 |
| users → bookmarks | 1:N | 一个用户可收藏多个内容 |
| users → ai_sessions | 1:N | 一个用户可有多个AI会话 |

---

## 5. 索引策略

| 表 | 索引 | 用途 |
|----|------|------|
| users | phone (unique) | 手机号登录查找 |
| plans | owner_id + deleted_at | 用户行程列表查询 |
| plans | status + deleted_at | 按状态筛选 |
| plan_pois | location (GIST) | 空间范围查询 |
| plan_pois | plan_id | 行程POI查询 |
| pois | location (GIST) | 空间范围搜索 |
| pois | category | 分类筛选 |
| pois | city | 城市筛选 |
| ai_sessions | user_id + created_at | 用户AI历史 |
| inspirations | featured + published_at | 首页Feed |

---

## 6. 数据迁移策略（从Demo数据到真实数据）

当前 v0.1 使用硬编码的 `demoPlans`、`demoPois` 常量。v1.0 迁移步骤：

1. 创建上述数据库表结构
2. 将 `demoPlans` 中的4条行程数据作为 seed 数据导入（标记为系统演示数据）
3. 将 `demoPois` 中的9个POI导入 `pois` 表
4. 保持 `_useMockMapPreview = true` 直到后端稳定后切换
5. 通过配置项控制数据源（本地Demo / 远程API）

---

## 7. 性能考量

| 场景 | 策略 |
|------|------|
| 首页行程列表 | 单次查询 plans + 联表 plan_days (count)，每页20条 |
| 行程详情 | plans JOIN plan_days JOIN plan_pois，一次查询 |
| POI空间搜索 | PostGIS ST_DWithin 空间索引，< 10ms |
| AI生成行程 | 异步任务，WebSocket推送进度，30秒超时 |
| 实时协作 | WebSocket + 乐观锁，冲突率 < 5% 直接合并 |

## 8. 备份与恢复

- 每日全量备份（PostgreSQL pg_dump），保留30天
- 持续归档（WAL archiving），支持时间点恢复（PITR）
- 地理数据使用 `pg_dump -Fc` 二进制格式保持 PostGIS 类型
