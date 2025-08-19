# API 接口文档

## 基础信息

- 服务器地址: `http://localhost:8000`
- 数据格式: JSON
- 字符编码: UTF-8

## 接口列表

### 1. 用户注册接口

#### 接口说明

用于新用户注册账户

#### 接口地址

```
POST /user/register
```

#### 请求参数

| 参数名           | 类型   | 必填 | 说明     |
| ---------------- | ------ | ---- | -------- |
| username         | string | 是   | 用户名   |
| password         | string | 是   | 密码     |
| confirm_password | string | 是   | 确认密码 |

#### 请求体示例

```json
{
  "username": "example_user",
  "password": "example_password",
  "confirm_password": "example_password"
}
```

#### 响应结果

| 参数名   | 类型   | 说明    |
| -------- | ------ | ------- |
| id       | string    | 用户 ID |
| username | string | 用户名  |

#### 响应示例

```json
{
  "id": 89989a21-e21a-4b4a-862f-033a404c0e1c,
  "username": "example_user"
}
```

### 2. 用户登录接口

#### 接口说明

用于已注册用户登录系统

#### 接口地址

```
POST /user/login
```

#### 请求参数

| 参数名   | 类型   | 必填 | 说明   |
| -------- | ------ | ---- | ------ |
| username | string | 是   | 用户名 |
| password | string | 是   | 密码   |

#### 请求体示例

```json
{
  "username": "example_user",
  "password": "example_password"
}
```

#### 响应结果

| 参数名  | 类型   | 说明         |
| ------- | ------ | ------------ |
| message | string | 登录消息     |
| user    | object | 用户信息对象 |

user 对象说明

| 参数名   | 类型   | 说明    |
| -------- | ------ | ------- |
| id       | int    | 用户 ID |
| username | string | 用户名  |

#### 响应示例

```json
{
  "message": "登录成功",
  "user": {
    "id": 1,
    "username": "example_user"
  }
}
```

### 3. 翻译接口 

#### 接口说明

翻译功能

#### 接口地址

```
POST /translate
```


#### 请求参数

| 参数名     | 类型   | 必填 | 说明                             |
| ---------- | ------ | ---- | -------------------------------- |
| target     | string | 是   | 目标语言，如 "en" 表示翻译为英语 |
| segments   | array  | 是   | 要翻译的文本片段列表             |
| extra_args | object | 否   | 翻译的额外要求，如风格、身份等   |

##### segments 参数说明

| 参数名 | 类型   | 必填 | 说明                                        |
| ------ | ------ | ---- | ------------------------------------------- |
| id     | string | 是   | 片段 ID，用于标识片段以便返回到前端相应位置 |
| text   | string | 是   | 要翻译的文本内容                            |
| model  | string | 否   | 模型名称，默认为 "qwen-turbo-latest"            |

##### extra_args 参数说明

| 参数名   | 类型   | 必填 | 说明                                                                 |
| -------- | ------ | ---- | -------------------------------------------------------------------- |
| style    | string | 否   | 翻译的风格要求，如"每句开头加上`😭`，在每句翻译后加上`😊`"          |
| identity | string | 否   | 翻译专家的身份，可选值："通用专家"、"学术论文翻译师"、"意译作家"、"程序专家"、"古今中外翻译师" |

#### 请求体示例

```json
{
  "target": "en",
  "segments": [
    {
      "id": "segment1",
      "text": "这是要翻译的文本"
    },
    {
      "id": "segment2",
      "text": "这是另一段要翻译的文本"
    }
  ],
  "extra_args": {
    "style": "每句开头加上`😭`，在每句翻译后加上`😊`",
    "identity": "意译作家"
  }
}
````

#### 响应结果

```json
{
  "translated": "en",
  "segments": [
    {
      "id": "segment1",
      "text": "😭This is the text to be translated😊"
    },
    {
      "id": "segment2",
      "text": "😭This is another text to be translated😊"
    }
  ]
}
```

### 4. OCR 文字识别接口

#### 接口说明

用于识别图片中的文字内容，支持多语言文字识别

#### 接口地址

```
POST /ocr
```

#### 请求参数

| 参数名 | 类型 | 必填 | 说明                                      |
| ------ | ---- | ---- | ----------------------------------------- |
| image  | file | 是   | 图片文件，支持常见图片格式（JPG、PNG 等） |

注意：该接口使用 form-data 格式上传文件

#### 请求示例

使用 curl 命令示例：

```bash
curl -X POST "http://localhost:8000/ocr" \
  -H "accept: application/json" \
  -H "Content-Type: multipart/form-data" \
  -F "image=@example.jpg"
```

#### 响应结果

| 参数名        | 类型   | 说明                                             |
| ------------- | ------ | ------------------------------------------------ |
| detected_text | array  | 检测到的文本列表，包括文本内容、置信度和位置信息 |
| full_text     | string | 完整的识别文本，每行文本以换行符分隔             |

##### detected_text 元素说明

| 参数名      | 类型   | 说明                                          |
| ----------- | ------ | --------------------------------------------- |
| text        | string | 识别的文本内容                                |
| confidence  | float  | 识别置信度，范围 0-1，越接近 1 表示置信度越高 |
| coordinates | array  | 文本框坐标，包含四个点的坐标信息              |

#### 响应示例

```json
{
  "detected_text": [
    {
      "text": "示例文本",
      "confidence": 0.9875345,
      "coordinates": [
        [10.0, 20.0],
        [100.0, 20.0],
        [100.0, 50.0],
        [10.0, 50.0]
      ]
    }
  ],
  "full_text": "示例文本"
}
```

### 5. OCR 翻译接口

#### 接口说明

用于识别图片中的文字内容并将其翻译成目标语言

#### 接口地址

```
POST /translate/ocr
```

#### 请求参数

| 参数名     | 类型   | 必填 | 说明                                      |
| ---------- | ------ | ---- | ----------------------------------------- |
| image      | file   | 是   | 图片文件，支持常见图片格式（JPG、PNG 等） |
| target     | string | 否   | 目标语言，默认为"zh"                      |
| model      | string | 否   | 模型名称，默认为"qwen-turbo-latest"       |
| extra_args | object | 否   | 翻译的额外要求，如风格、身份等            |

注意：该接口使用 form-data 格式上传文件

##### extra_args 参数说明

| 参数名   | 类型   | 必填 | 说明                                                                                           |
| -------- | ------ | ---- | ---------------------------------------------------------------------------------------------- |
| style    | string | 否   | 翻译的风格要求，如"每句开头加上`😭`，在每句翻译后加上`😊`"                                     |
| identity | string | 否   | 翻译专家的身份，可选值："通用专家"、"学术论文翻译师"、"意译作家"、"程序专家"、"古今中外翻译师" |

#### 请求示例

使用 curl 命令示例：

```bash
curl -X POST "http://localhost:8000/translate/ocr" \
  -H "accept: application/json" \
  -H "Content-Type: multipart/form-data" \
  -F "image=@example.jpg" \
  -F "target=en"
```

#### 响应结果

| 参数名          | 类型   | 说明                                             |
| --------------- | ------ | ------------------------------------------------ |
| translated      | string | 翻译的目标语言                                   |
| detected_text   | array  | 检测到的文本列表，包括文本内容、置信度和位置信息 |
| full_text       | string | 完整的识别文本，每行文本以换行符分隔             |
| translated_text | string | 翻译后的文本内容                                 |

#### 响应示例

```json
{
  "translated": "en",
  "detected_text": [
    {
      "text": "示例文本",
      "confidence": 0.9875345,
      "coordinates": [
        [10.0, 20.0],
        [100.0, 20.0],
        [100.0, 50.0],
        [10.0, 50.0]
      ]
    }
  ],
  "full_text": "示例文本",
  "translated_text": "Sample text"
}
```

### 6. 单词翻译接口

#### 接口说明

专门用于单词或短语翻译的接口，支持批量翻译多个单词

#### 接口地址

```
POST /trans-word
```

#### 请求参数

| 参数名     | 类型   | 必填 | 说明                                |
| ---------- | ------ | ---- | ----------------------------------- |
| word       | array  | 是   | 要翻译的单词或短语列表              |
| target     | string | 否   | 目标语言，默认为"中文"              |
| model      | string | 否   | 模型名称，默认为"qwen-turbo-latest" |
| extra_args | object | 否   | 翻译的额外要求，如风格、身份等      |

##### word 参数说明

| 参数名 | 类型   | 必填 | 说明                                        |
| ------ | ------ | ---- | ------------------------------------------- |
| id     | string | 是   | 单词 ID，用于标识单词以便返回到前端相应位置 |
| word   | string | 是   | 要翻译的单词或短语内容                      |

##### extra_args 参数说明

| 参数名   | 类型   | 必填 | 说明                                                                                           |
| -------- | ------ | ---- | ---------------------------------------------------------------------------------------------- |
| style    | string | 否   | 翻译的风格要求，如"每句开头加上`😭`，在每句翻译后加上`😊`"                                     |
| identity | string | 否   | 翻译专家的身份，可选值："通用专家"、"学术论文翻译师"、"意译作家"、"程序专家"、"古今中外翻译师" |

#### 请求体示例

```json
{
  "word": [
    {
      "id": "word1",
      "word": "hello"
    },
    {
      "id": "word2",
      "word": "world"
    }
  ],
  "target": "中文",
  "extra_args": {
    "identity": "通用专家"
  }
}
```

#### 响应结果

```json
{
  "translated_word": [
    {
      "id": "word1",
      "word": "你好"
    },
    {
      "id": "word2",
      "word": "世界"
    }
  ]
}
```

### 7. 文本转语音接口

#### 接口说明

用于将文本转换为语音（TTS），支持生成 WAV 格式的音频文件

#### 接口地址

```
POST /tts
```

#### 请求参数

| 参数名     | 类型   | 必填 | 说明                   |
| ---------- | ------ | ---- | ---------------------- |
| full_text  | string | 是   | 要转换为语音的完整文本 |
| extra_args | object | 否   | 额外参数，如风格等     |

##### extra_args 参数说明

| 参数名 | 类型   | 必填 | 说明                     |
| ------ | ------ | ---- | ------------------------ |
| style  | string | 否   | 语音风格要求（预留参数） |

#### 请求体示例

```json
{
  "full_text": "你好，世界！",
  "extra_args": {
    "style": "正式"
  }
}
```

#### 响应结果

响应为 WAV 格式的音频文件，直接以二进制流形式返回。

响应头包含：

- Content-Type: audio/wav
- Content-Disposition: 附件形式，包含文件名

#### 响应示例

返回一个 WAV 格式的音频文件，可直接播放或下载。

### 8. 单词记录接口

#### 接口说明

用于记录用户翻译过的单词，系统会自动将句子拆分成单词并过滤掉人名、地名、特殊单词等，只记录普通的日常词汇。

#### 接口地址

```
POST /word/record
```

#### 请求参数

| 参数名          | 类型   | 必填 | 说明                                |
| --------------- | ------ | ---- | ----------------------------------- |
| user_id         | string | 是   | 用户ID                              |
| text            | string | 是   | 要处理的文本                        |
| target_language | string | 否   | 目标语言，默认为"中文"              |
| model_name      | string | 否   | 使用的模型名称，默认为"qwen-turbo-latest" |

#### 请求体示例

```json
{
  "user_id": "7c03eb20-4525-4480-ae36-ecef8013a814",
  "text": "Hello world, how are you today?",
  "target_language": "中文",
  "model_name": "qwen-turbo-latest"
}
```

#### 响应结果

| 参数名  | 类型   | 说明         |
| ------- | ------ | ------------ |
| message | string | 操作消息     |
| records | array  | 记录的单词列表 |

##### records 元素说明

| 参数名          | 类型   | 说明                                |
| --------------- | ------ | ----------------------------------- |
| id              | string | 记录的唯一标识符                    |
| user_id         | string | 用户ID                              |
| word            | string | 记录的单词                          |
| original_text   | string | 原始文本（句子）                    |
| translated_text | string | 翻译后的文本（可选）                |
| target_language | string | 目标语言                            |
| model_name      | string | 使用的翻译模型                      |
| created_at      | string | 创建时间                            |

#### 响应示例

```json
{
  "message": "单词记录成功",
  "records": [
    {
      "id": "73424a02-cc65-468c-bedd-80e8d45fcc42",
      "user_id": "7c03eb20-4525-4480-ae36-ecef8013a814",
      "word": "hello",
      "original_text": "Hello world, how are you today?",
      "translated_text": null,
      "target_language": "中文",
      "model_name": "qwen-turbo-latest",
      "created_at": "2025-08-19 17:02:03.683303"
    },
    {
      "id": "b69c15e6-ec6b-4afb-b120-675966ec92ff",
      "user_id": "7c03eb20-4525-4480-ae36-ecef8013a814",
      "word": "world",
      "original_text": "Hello world, how are you today?",
      "translated_text": null,
      "target_language": "中文",
      "model_name": "qwen-turbo-latest",
      "created_at": "2025-08-19 17:02:04.104836"
    }
  ]
}
```

### 9. 获取用户单词记录接口

#### 接口说明

获取指定用户的单词记录列表

#### 接口地址

```
GET /word/records/{user_id}
```

#### 请求参数

| 参数名   | 类型 | 必填 | 说明                                |
| -------- | ---- | ---- | ----------------------------------- |
| user_id  | string | 是   | 用户ID（路径参数）                  |
| limit    | int  | 否   | 限制返回数量，默认为100             |
| offset   | int  | 否   | 偏移量，默认为0                     |

#### 请求示例

```bash
curl -X GET "http://localhost:8000/word/records/7c03eb20-4525-4480-ae36-ecef8013a814?limit=10&offset=0"
```

#### 响应结果

响应格式同单词记录接口

#### 响应示例

```json
{
  "message": "获取单词记录成功",
  "records": [
    {
      "id": "3880814c-1593-488f-803e-919f74c73256",
      "user_id": "7c03eb20-4525-4480-ae36-ecef8013a814",
      "word": "today",
      "original_text": "Hello world, how are you today?",
      "translated_text": null,
      "target_language": "中文",
      "model_name": "qwen-turbo-latest",
      "created_at": "2025-08-19 17:02:05.788975"
    }
  ]
}
```

### 10. 搜索单词记录接口

#### 接口说明

搜索用户的单词记录，支持按单词和目标语言筛选

#### 接口地址

```
POST /word/search
```

#### 请求参数

| 参数名          | 类型   | 必填 | 说明                                |
| --------------- | ------ | ---- | ----------------------------------- |
| user_id         | string | 是   | 用户ID                              |
| word            | string | 否   | 搜索的单词（支持模糊匹配）          |
| target_language | string | 否   | 目标语言                            |

#### 请求体示例

```json
{
  "user_id": "7c03eb20-4525-4480-ae36-ecef8013a814",
  "word": "hello",
  "target_language": "中文"
}
```

#### 响应结果

响应格式同单词记录接口

#### 响应示例

```json
{
  "message": "搜索单词记录成功",
  "records": [
    {
      "id": "73424a02-cc65-468c-bedd-80e8d45fcc42",
      "user_id": "7c03eb20-4525-4480-ae36-ecef8013a814",
      "word": "hello",
      "original_text": "Hello world, how are you today?",
      "translated_text": null,
      "target_language": "中文",
      "model_name": "qwen-turbo-latest",
      "created_at": "2025-08-19 17:02:03.683303"
    }
  ]
}
```

## 单词记录功能说明

### 功能概述

单词记录功能允许系统自动记录用户翻译过的单词，并将句子拆分成单词后存储到数据库中。系统会过滤掉人名、地名、特殊单词等，只记录普通的日常词汇。

### 数据库表结构

#### word_record 表

```sql
CREATE TABLE word_record (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    word VARCHAR(100) NOT NULL,
    original_text TEXT NOT NULL,
    translated_text TEXT,
    target_language VARCHAR(10) NOT NULL,
    model_name VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, word, target_language)
);
```

字段说明：
- `id`: 记录的唯一标识符
- `user_id`: 用户ID，关联到users表
- `word`: 记录的单词
- `original_text`: 原始文本（句子）
- `translated_text`: 翻译后的文本（可选）
- `target_language`: 目标语言
- `model_name`: 使用的翻译模型
- `created_at`: 创建时间

### 单词过滤规则

系统使用两层过滤机制来判断单词是否为普通单词：

#### 1. 基本过滤规则
- 单词长度：2-50个字符
- 不包含数字
- 只包含字母、连字符和撇号
- 不是全大写缩写（3个字符以内）
- 不以大写字母开头

#### 2. AI智能判断
使用大模型判断单词是否为普通单词，排除以下类型：
- 人名：John, Mary, Smith等
- 地名：London, Paris, Beijing等
- 品牌名：Apple, Nike, Coca-Cola等
- 专业术语：algorithm, photosynthesis等
- 缩写：USA, DNA, CEO等
- 网络用语：LOL, OMG等

### 翻译时自动记录

在翻译接口中，如果提供了`user_id`参数，系统会自动记录翻译文本中的单词：

```json
{
  "target": "中文",
  "segments": [
    {
      "id": "1",
      "text": "Hello world, how are you today?",
      "model": "qwen-turbo-latest"
    }
  ],
  "user_id": "7c03eb20-4525-4480-ae36-ecef8013a814"
}
```

### 使用示例

#### 1. 记录单词

```bash
curl -X POST "http://localhost:8000/word/record" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "7c03eb20-4525-4480-ae36-ecef8013a814",
    "text": "Hello world, how are you today?",
    "target_language": "中文",
    "model_name": "qwen-turbo-latest"
  }'
```

#### 2. 翻译时自动记录

```bash
curl -X POST "http://localhost:8000/translate" \
  -H "Content-Type: application/json" \
  -d '{
    "target": "中文",
    "segments": [
      {
        "id": "1",
        "text": "Hello world, how are you today?",
        "model": "qwen-turbo-latest"
      }
    ],
    "user_id": "7c03eb20-4525-4480-ae36-ecef8013a814"
  }'
```

#### 3. 获取单词记录

```bash
curl -X GET "http://localhost:8000/word/records/7c03eb20-4525-4480-ae36-ecef8013a814?limit=10&offset=0"
```

### 注意事项

1. 确保数据库连接配置正确
2. 需要配置相应的大模型API密钥
3. 单词记录功能是异步的，不会影响翻译性能
4. 如果AI判断失败，系统会默认认为是普通单词
5. 同一用户对同一单词在同一目标语言下的记录会更新而不是重复创建

### 错误处理

- 如果数据库连接失败，会记录错误日志但不影响翻译功能
- 如果AI判断失败，会记录警告日志并默认认为是普通单词
- 所有错误都会在日志中记录详细信息
