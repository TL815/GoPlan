# GoPlan API 接口设计文档

> 版本 v1.0 | 状态：设计阶段

## 1. 设计原则

- RESTful 风格，资源导向的 URL 设计
- 统一响应格式，所有接口返回 JSON
- JWT Token 认证，Authorization Header 传递
- 分页、排序、过滤参数标准化
- 版本号通过 URL 路径前缀管理（`/api/v1/`）

## 2. 通用规范

### 2.1 基础 URL

```
开发环境: https://dev-api.goplan.cn/api/v1
生产环境: https://api.goplan.cn/api/v1
```

### 2.2 通用请求头

| Header | 值 | 说明 |
|--------|-----|------|
| `Content-Type` | `application/json` | 请求体格式 |
| `Authorization` | `Bearer {token}` | 用户认证Token |
| `Accept-Language` | `zh-CN` | 语言偏好 |
| `X-Client-Version` | `1.0.0` | 客户端版本号 |

### 2.3 统一响应格式

```json
{
  "code": 0,
  "message": "success",
  "data": {},
  "timestamp": 1719705600000
}
```

### 2.4 错误码定义

| Code | 说明 |
|------|------|
| 0 | 成功 |
| 10001 | 参数错误 |
| 10002 | 未登录/Token过期 |
| 10003 | 权限不足 |
| 10004 | 资源不存在 |
| 10005 | 操作冲突（如重复创建） |
| 20001 | AI服务异常 |
| 20002 | AI生成失败 |
| 30001 | 地图服务异常 |
| 50001 | 服务器内部错误 |

### 2.5 分页规范

```json
{
  "page": 1,
  "page_size": 20,
  "total": 156,
  "total_pages": 8,
  "items": []
}
```

---

## 3. 认证模块

### 3.1 发送验证码

```
POST /auth/send-code
```

**请求体**
```json
{
  "phone": "13800138000"
}
```

**响应**
```json
{
  "code": 0,
  "message": "验证码已发送",
  "data": { "expire_seconds": 300 }
}
```

### 3.2 登录/注册

```
POST /auth/login
```

**请求体**
```json
{
  "phone": "13800138000",
  "code": "123456"
}
```

**响应**
```json
{
  "code": 0,
  "data": {
    "token": "eyJhbG...",
    "refresh_token": "eyJhbG...",
    "expires_in": 86400,
    "user": {
      "id": "u_abc123",
      "nickname": "旅行者张三",
      "avatar": "https://cdn.goplan.cn/avatars/abc123.webp",
      "phone": "138****8000",
      "created_at": "2026-01-01T00:00:00Z"
    }
  }
}
```

### 3.3 刷新Token

```
POST /auth/refresh
```

**请求体**
```json
{
  "refresh_token": "eyJhbG..."
}
```

### 3.4 登出

```
POST /auth/logout
```

---

## 4. 用户模块

### 4.1 获取用户信息

```
GET /users/me
```

**响应**
```json
{
  "code": 0,
  "data": {
    "id": "u_abc123",
    "nickname": "旅行者张三",
    "avatar": "https://cdn.goplan.cn/avatars/abc123.webp",
    "bio": "热爱山川湖海",
    "travel_count": 12,
    "plan_count": 5
  }
}
```

### 4.2 更新用户信息

```
PATCH /users/me
```

**请求体**
```json
{
  "nickname": "新昵称",
  "avatar": "https://...",
  "bio": "新的简介"
}
```

---

## 5. 行程模块

### 5.1 行程列表

```
GET /plans
```

**查询参数**

| 参数 | 类型 | 说明 |
|------|------|------|
| `page` | int | 页码 |
| `page_size` | int | 每页数量 |
| `status` | string | 筛选状态：planning/ongoing/completed |
| `sort` | string | 排序：created_at/start_date |

**响应**
```json
{
  "code": 0,
  "data": {
    "page": 1,
    "page_size": 20,
    "total": 5,
    "items": [
      {
        "id": "p_001",
        "title": "青甘大环线10天游",
        "cover": "https://cdn.goplan.cn/covers/p_001.webp",
        "destination": "青海·甘肃",
        "start_date": "2026-07-15",
        "end_date": "2026-07-25",
        "days": 10,
        "places_count": 15,
        "members_count": 4,
        "status": "planning",
        "countdown": 17,
        "accent_color": "#69A7FF",
        "created_at": "2026-06-01T00:00:00Z"
      }
    ]
  }
}
```

### 5.2 行程详情

```
GET /plans/{plan_id}
```

**响应**（关键字段）
```json
{
  "code": 0,
  "data": {
    "id": "p_001",
    "title": "青甘大环线10天游",
    "cover": "https://...",
    "destination": "青海·甘肃",
    "start_date": "2026-07-15",
    "end_date": "2026-07-25",
    "days": 10,
    "members": [
      { "id": "u_abc123", "nickname": "张三", "avatar": "https://...", "role": "owner" },
      { "id": "u_def456", "nickname": "李四", "avatar": "https://...", "role": "editor" }
    ],
    "days_schedule": [
      {
        "day": 1,
        "date": "2026-07-15",
        "weather": { "temp_high": 28, "temp_low": 15, "condition": "sunny" },
        "pois": [
          {
            "id": "poi_001",
            "poi_id": "poi_xining",
            "name": "西宁",
            "category": "transport",
            "latitude": 36.6171,
            "longitude": 101.7782,
            "order": 1,
            "start_time": "09:00",
            "duration_minutes": 0,
            "note": "集合出发点"
          }
        ]
      }
    ],
    "route": {
      "center": { "latitude": 38.0, "longitude": 98.0 },
      "zoom": 7,
      "stops": [
        { "name": "西宁", "latitude": 36.6171, "longitude": 101.7782, "order": 1, "is_start": true },
        { "name": "青海湖", "latitude": 36.9869, "longitude": 99.9064, "order": 2 },
        { "name": "张掖", "latitude": 38.9317, "longitude": 100.4555, "order": 5, "is_end": true }
      ]
    },
    "accent_color": "#69A7FF",
    "status": "planning"
  }
}
```

### 5.3 创建行程

```
POST /plans
```

**请求体**
```json
{
  "title": "青甘大环线10天游",
  "destination": "青海·甘肃",
  "start_date": "2026-07-15",
  "end_date": "2026-07-25",
  "accent_color": "#69A7FF"
}
```

### 5.4 更新行程

```
PATCH /plans/{plan_id}
```

支持更新的字段：`title`, `cover`, `start_date`, `end_date`, `accent_color`, `status`

### 5.5 删除行程

```
DELETE /plans/{plan_id}
```

### 5.6 添加/更新日行程POI

```
POST /plans/{plan_id}/days/{day}/pois
```

**请求体**
```json
{
  "poi_id": "poi_xining",
  "name": "西宁",
  "category": "transport",
  "latitude": 36.6171,
  "longitude": 101.7782,
  "order": 1,
  "start_time": "09:00",
  "note": "集合出发点"
}
```

### 5.7 调整POI顺序

```
PATCH /plans/{plan_id}/days/{day}/pois/reorder
```

**请求体**
```json
{
  "poi_ids": ["poi_003", "poi_001", "poi_002"]
}
```

### 5.8 删除日行程POI

```
DELETE /plans/{plan_id}/days/{day}/pois/{poi_id}
```

---

## 6. AI 行程生成模块

### 6.1 AI对话生成行程

```
POST /ai/generate-plan
```

**请求体**
```json
{
  "prompt": "想去云南玩7天，喜欢拍照和美食，不喜欢太赶的行程",
  "reference_links": [
    "https://www.xiaohongshu.com/explore/xxx"
  ],
  "preferences": {
    "style": "relaxed",
    "interests": ["photography", "food"],
    "budget": "medium"
  }
}
```

**响应**
```json
{
  "code": 0,
  "data": {
    "session_id": "ai_sess_001",
    "plan_preview": {
      "title": "云南7日慢游·摄影美食之旅",
      "destination": "云南",
      "suggested_days": 7,
      "days_schedule": [
        {
          "day": 1,
          "theme": "抵达昆明，初探春城",
          "pois": [
            {
              "name": "昆明长水机场",
              "category": "transport",
              "latitude": 25.1019,
              "longitude": 102.9291,
              "suggestion": "抵达后前往市区"
            },
            {
              "name": "翠湖公园",
              "category": "scenic",
              "latitude": 25.0453,
              "longitude": 102.7056,
              "suggestion": "傍晚散步拍照，可拍红嘴鸥"
            }
          ]
        }
      ],
      "highlights": ["大理洱海日出拍摄", "丽江古城夜景", "野生菌火锅"],
      "tips": ["云南海拔差异大，注意衣物分层", "防晒必备", "7月为雨季，带雨具"]
    }
  }
}
```

### 6.2 攻略链接解析

```
POST /ai/parse-guide
```

**请求体**
```json
{
  "url": "https://www.xiaohongshu.com/explore/xxx"
}
```

**响应**
```json
{
  "code": 0,
  "data": {
    "source": "xiaohongshu",
    "title": "云南7天6晚超详细攻略！拍照美食两不误",
    "extracted_pois": [
      { "name": "翠湖公园", "category": "scenic", "latitude": 25.0453, "longitude": 102.7056, "confidence": 0.95 },
      { "name": "大理古城", "category": "scenic", "latitude": 25.6820, "longitude": 100.1630, "confidence": 0.98 }
    ],
    "suggested_route": { "days": 7, "city_order": ["昆明", "大理", "丽江"] },
    "raw_text_summary": "这是一篇关于云南7日游的详细攻略..."
  }
}
```

### 6.3 行程优化建议

```
POST /ai/optimize-plan/{plan_id}
```

**请求体**
```json
{
  "optimize_type": "route_efficiency"
}
```

**响应**
```json
{
  "code": 0,
  "data": {
    "suggestions": [
      {
        "type": "route",
        "severity": "info",
        "day": 3,
        "message": "建议将「苍山」调整到上午，下午阳光方向更利于「洱海」拍照",
        "affected_pois": ["poi_cangshan", "poi_erhai"]
      }
    ]
  }
}
```

---

## 7. 协作模块

### 7.1 邀请协作者

```
POST /plans/{plan_id}/members
```

**请求体**
```json
{
  "phone": "13900139000",
  "role": "editor"
}
```

### 7.2 移除协作者

```
DELETE /plans/{plan_id}/members/{user_id}
```

### 7.3 获取行程协作成员

```
GET /plans/{plan_id}/members
```

---

## 8. POI 搜索模块

### 8.1 POI 搜索

```
GET /pois/search
```

| 参数 | 类型 | 说明 |
|------|------|------|
| `keyword` | string | 搜索关键词 |
| `category` | string | scenic/food/hotel/shopping/transport |
| `latitude` | float | 中心纬度 |
| `longitude` | float | 中心经度 |
| `radius` | int | 搜索半径（米） |
| `page` | int | 页码 |

### 8.2 POI 详情

```
GET /pois/{poi_id}
```

### 8.3 POI 附近推荐

```
GET /pois/nearby
```

---

## 9. 旅行灵感Feed模块

### 9.1 灵感Feed列表

```
GET /inspirations
```

**查询参数**

| 参数 | 类型 | 说明 |
|------|------|------|
| `category` | string | destination/food/photo/hidden_gem |
| `page` | int | 页码 |

### 9.2 收藏目的地

```
POST /inspirations/{inspiration_id}/bookmark
```

---

## 10. 文件上传模块

### 10.1 上传图片

```
POST /files/upload
```

Content-Type: `multipart/form-data`

| 字段 | 说明 |
|------|------|
| `file` | 图片文件（≤10MB，jpg/png/webp） |
| `type` | avatar/cover/poi_photo/post |

**响应**
```json
{
  "code": 0,
  "data": {
    "url": "https://cdn.goplan.cn/uploads/2026/06/abc123.webp",
    "thumbnail_url": "https://cdn.goplan.cn/uploads/2026/06/abc123_thumb.webp"
  }
}
```

---

## 11. WebSocket 实时协作

### 11.1 建立连接

```
wss://api.goplan.cn/ws/plan/{plan_id}?token={jwt_token}
```

### 11.2 消息协议

**客户端→服务端**
```json
{
  "type": "poi_update",
  "payload": {
    "day": 2,
    "poi_id": "poi_005",
    "changes": { "start_time": "10:00" }
  }
}
```

**服务端→客户端（广播）**
```json
{
  "type": "poi_updated",
  "user_id": "u_def456",
  "user_name": "李四",
  "timestamp": 1719705600000,
  "payload": {
    "day": 2,
    "poi_id": "poi_005",
    "changes": { "start_time": "10:00" }
  }
}
```

---

## 12. 第三方服务集成

### 12.1 高德地图API

| 用途 | API | 说明 |
|------|-----|------|
| POI搜索 | `amap.poi.search` | 关键词+区域搜索 |
| 地理编码 | `amap.geocode` | 地址→坐标 |
| 逆地理编码 | `amap.regeocode` | 坐标→地址 |
| 路径规划 | `amap.direction` | 驾车/步行/公交路径 |
| 天气查询 | `amap.weather` | 目的地天气预报 |

### 12.2 攻略解析管道

```
用户粘贴链接 → 后端爬取内容 → NLP实体识别 → 高德POI匹配 → 时序推断 → 返回结构化行程
```

---

## 13. 限流策略

| 接口类别 | 限制 | 窗口 |
|---------|------|------|
| 发送验证码 | 1次/分钟，5次/天 | 按手机号 |
| AI生成行程 | 20次/天 | 按用户 |
| 攻略解析 | 30次/天 | 按用户 |
| 图片上传 | 50次/天 | 按用户 |
| 普通API | 100次/分钟 | 按用户 |
