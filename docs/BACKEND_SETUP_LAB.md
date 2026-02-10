# 🚀 HƯỚNG DẪN SETUP BACKEND AWS - STEP BY STEP LAB

## 📚 Giới thiệu

Hướng dẫn này sẽ giúp bạn setup backend AWS cho Coffee Shop từ đầu đến cuối theo từng chức năng cụ thể. Mỗi chức năng sẽ được thực hiện đầy đủ từ API Gateway → Lambda → DynamoDB.

**Phương pháp học**: Vừa làm vừa học lý thuyết, hiểu rõ từng bước và từng khái niệm.

---

## 🎯 Thứ tự thực hiện theo chức năng

1. **Chức năng 1**: Xem danh sách sản phẩm (GET /products)
2. **Chức năng 2**: Tạo đơn hàng (POST /orders)
3. **Chức năng 3**: Xem lịch sử đơn hàng (GET /orders)
4. **Chức năng 4**: Đăng ký tài khoản (POST /auth/register)
5. **Chức năng 5**: Đăng nhập (POST /auth/login)

---

## 📋 Prerequisites

- Tài khoản AWS (Free tier)
- Trình duyệt web
- Hiểu biết cơ bản về HTTP methods (GET, POST)
- Postman hoặc Thunder Client để test API

---

## 🧪 LAB 1: XEM DANH SÁCH SẢN PHẨM

### 📖 Lý thuyết: Tại sao bắt đầu với chức năng này?

Đây là chức năng đơn giản nhất và không cần authentication. Chúng ta sẽ học các khái niệm cơ bản:
- DynamoDB Table
- Lambda Function
- API Gateway REST API
- Lambda Proxy Integration

---

## BƯỚC 1.1: TẠO DYNAMODB TABLE - COFFEEPRODUCTS

### 📚 Lý thuyết: DynamoDB là gì?

**Tài liệu tham khảo**: [AWS DynamoDB Documentation](https://docs.aws.amazon.com/dynamodb/latest/developerguide/Introduction.html)

**DynamoDB** là dịch vụ NoSQL database của AWS, được thiết kế để:
- **Serverless**: Không cần quản lý server
- **Scalable**: Tự động scale theo traffic
- **Fast**: Độ trễ milliseconds
- **Flexible schema**: Không cần định nghĩa schema cứng nhắc

**Các khái niệm quan trọng**:

1. **Table**: Bảng lưu trữ data (giống như table trong SQL)
2. **Item**: Một record trong bảng (giống như row trong SQL)
3. **Attribute**: Một field của item (giống như column trong SQL)
4. **Primary Key**: Khóa chính để identify unique item, gồm:
   - **Partition Key** (bắt buộc): Key để DynamoDB phân tán data
   - **Sort Key** (optional): Key để sắp xếp data

**Partition Key vs Sort Key**:
- **Partition Key alone**: Mỗi item có 1 key duy nhất
  ```
  Ví dụ: productId = "prod-123"
  ```
- **Partition Key + Sort Key**: Combine để tạo unique key
  ```
  Ví dụ: 
  orderId (partition) + createdAt (sort)
  → Cho phép 1 order có nhiều versions theo time
  ```

**Billing Mode**:
- **Provisioned**: Bạn set trước capacity (read/write units) → Rẻ hơn nếu traffic stable
- **On-Demand**: Pay per request → Phù hợp cho traffic không đều

**Tài liệu**: [DynamoDB Core Components](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.CoreComponents.html)

---

### � Lý thuyết: DynamoDB Data Types

**Tài liệu tham khảo**: [DynamoDB Data Types](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.NamingRulesDataTypes.html#HowItWorks.DataTypes)

DynamoDB lưu trữ data với **type annotations** (type descriptors) để phân biệt data types.

**Các Data Types phổ biến**:

1. **String (S)**: Text data
   ```json
   {"productId": {"S": "prod-001"}}
   ```

2. **Number (N)**: Số (integer hoặc float, lưu dạng string)
   ```json
   {"price": {"N": "300000"}}
   {"rating": {"N": "4.5"}}
   ```
   **Lưu ý**: Number được lưu dạng string để tránh precision issues

3. **Boolean (BOOL)**: true/false
   ```json
   {"inStock": {"BOOL": true}}
   ```

4. **String Set (SS)**: Tập hợp các strings (unique, unordered)
   ```json
   {"sizes": {"SS": ["8OZ", "12OZ"]}}
   ```

5. **Number Set (NS)**: Tập hợp các numbers
   ```json
   {"ratings": {"NS": ["4", "5", "3"]}}
   ```

6. **List (L)**: Mảng có thứ tự, mixed types
   ```json
   {"items": {"L": [
     {"S": "Coffee"},
     {"N": "2"},
     {"BOOL": true}
   ]}}
   ```

7. **Map (M)**: Object nested
   ```json
   {"address": {"M": {
     "city": {"S": "Hanoi"},
     "zipCode": {"N": "100000"}
   }}}
   ```

8. **Null (NULL)**: Null value
   ```json
   {"description": {"NULL": true}}
   ```

**Ví dụ item đầy đủ**:
```json
{
  "productId": {"S": "prod-001"},
  "nameProduct": {"S": "Default Route Coffee"},
  "price": {"SS": ["300000", "450000"]},
  "sizes": {"SS": ["8OZ", "12OZ"]},
  "stock": {"N": "100"},
  "inStock": {"BOOL": true}
}
```

---

### 📚 Lý thuyết: DocumentClient vs Low-Level Client

**AWS SDK cung cấp 2 cách làm việc với DynamoDB**:

#### 1️⃣ Low-Level Client (`DynamoDBClient`)

**Đặc điểm**:
- Làm việc trực tiếp với DynamoDB JSON format (có type annotations)
- Phải manually specify types (S, N, SS, etc.)
- Verbose nhưng có full control

**Ví dụ code**:
```javascript
import { DynamoDBClient, PutItemCommand } from "@aws-sdk/client-dynamodb";

const client = new DynamoDBClient({ region: "ap-southeast-1" });

// Phải specify types manually
const result = await client.send(new PutItemCommand({
  TableName: "CoffeeProducts",
  Item: {
    productId: { S: "prod-001" },
    nameProduct: { S: "Coffee" },
    price: { N: "300000" },
    inStock: { BOOL: true }
  }
}));
```

**Khi nào dùng**: 
- Cần performance cao (ít overhead)
- Làm việc với complex data types
- Migration từ SDK v2

#### 2️⃣ DocumentClient (`DynamoDBDocumentClient`)

**Đặc điểm**:
- **Tự động convert** giữa JavaScript objects ↔ DynamoDB format
- Viết code đơn giản hơn (giống MongoDB, SQL ORM)
- Recommended cho hầu hết use cases

**Ví dụ code**:
```javascript
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, PutCommand } from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({ region: "ap-southeast-1" });
const docClient = DynamoDBDocumentClient.from(client);

// Không cần specify types, tự động convert!
const result = await docClient.send(new PutCommand({
  TableName: "CoffeeProducts",
  Item: {
    productId: "prod-001",
    nameProduct: "Coffee",
    price: 300000,
    inStock: true
  }
}));
```

**Type conversions tự động**:
- JavaScript `string` → DynamoDB `{S: "..."}`
- JavaScript `number` → DynamoDB `{N: "..."}`
- JavaScript `boolean` → DynamoDB `{BOOL: ...}`
- JavaScript `Array` → DynamoDB `{L: [...]}` hoặc `{SS: [...]}` (nếu all strings)
- JavaScript `Object` → DynamoDB `{M: {...}}`
- JavaScript `null` → DynamoDB `{NULL: true}`

**Khi nào dùng**:
- ✅ Hầu hết các trường hợp (recommended)
- ✅ Code đơn giản, dễ maintain
- ✅ Rapid development

**So sánh**:

| Feature | Low-Level Client | DocumentClient |
|---------|-----------------|----------------|
| **Code complexity** | Verbose | Simple |
| **Type annotations** | Manual | Automatic |
| **Performance** | Slightly faster | Good enough |
| **Use case** | Advanced scenarios | Most applications |
| **Learning curve** | Steep | Gentle |

**Trong các LAB này, chúng ta sẽ dùng DocumentClient** vì:
1. Code đơn giản, dễ hiểu
2. Phù hợp cho learning và development
3. Performance difference không đáng kể cho scale này

**Tài liệu**: 
- [Low-Level Client](https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/client/dynamodb/)
- [DocumentClient](https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/lib-dynamodb/)

---

### �🔨 Thực hành: Tạo bảng CoffeeProducts

**Bước 1**: Truy cập DynamoDB Console

1. Đăng nhập AWS Console: https://console.aws.amazon.com
2. Tìm kiếm "DynamoDB" trong thanh search
3. Click vào **DynamoDB**
4. Chọn region **Asia Pacific (Singapore) ap-southeast-1** (góc phải trên)
   - **Lý do**: Gần Việt Nam → latency thấp

**Bước 2**: Tạo Table mới

1. Click nút **Create table** (màu cam)
2. Điền thông tin:

```
Table name: CoffeeProducts
```

**Giải thích**: Tên table nên rõ ràng, dễ hiểu. Prefix "Coffee" giúp identify project.

```
Partition key: productId (String)
```

**Giải thích**: 
- `productId` là unique identifier cho mỗi sản phẩm
- Type `String` vì ID thường là text (ví dụ: "prod-001", "uuid-xxxx")
- **Không cần Sort key** vì mỗi product chỉ có 1 record

```
Table settings: 
[•] On-demand
[ ] Provisioned
```

**Giải thích**:
- Chọn **On-demand** vì:
  - Dễ dàng cho development/testing
  - Không cần estimate capacity
  - Traffic không đều (có khi nhiều, có khi ít)
  - Free tier: 25 GB storage + 2.5M read/write requests/month

3. Scroll xuống, giữ nguyên settings khác (default)
4. Click **Create table**
5. Đợi ~10-30 giây cho table được tạo (status: Active)

**Bước 3**: Verify Table đã tạo thành công

1. Trong DynamoDB console, click vào table **CoffeeProducts**
2. Tab **Overview** → Xem thông tin:
   - Table ARN (Amazon Resource Name)
   - Item count (hiện tại = 0)
   - Table size

**Bước 4**: Thêm sample products (optional - để test)

1. Tab **Explore table items**
2. Click **Create item**
3. **View**: Chọn **JSON view** (góc phải)
4. Paste JSON sau (DynamoDB format với type annotations):

```json
{
  "productId": {"S": "prod-001"},
  "nameProduct": {"S": "Default Route Coffee"},
  "price": {"SS": ["300.000 VND", "450.000 VND"]},
  "sizes": {"SS": ["8OZ", "12OZ"]},
  "note": {"S": "100% Natural notes of Berries, Chocolate, & Caramel! Scoring 85+."},
  "imageUrl": {"S": "https://example.com/image1.jpg"},
  "createdAt": {"N": "1707523200000"},
  "updatedAt": {"N": "1707523200000"}
}
```

**Giải thích format**:
- `{"S": "value"}` = String type
- `{"N": "123"}` = Number type (lưu dạng string)
- `{"SS": ["a", "b"]}` = String Set (array of unique strings)
- **Lý do**: Đây là DynamoDB JSON format chuẩn khi tạo item manually trong console

5. Click **Create item**

6. Lặp lại để tạo thêm 3 products:

**Product 2**:
```json
{
  "productId": {"S": "prod-002"},
  "nameProduct": {"S": "Bloom Coffee"},
  "price": {"SS": ["350.000 VND", "500.000 VND"]},
  "sizes": {"SS": ["8OZ", "12OZ"]},
  "note": {"S": "Floral and fruity notes with smooth finish."},
  "imageUrl": {"S": "https://example.com/image2.jpg"},
  "createdAt": {"N": "1707523200000"},
  "updatedAt": {"N": "1707523200000"}
}
```

**Product 3**:
```json
{
  "productId": {"S": "prod-003"},
  "nameProduct": {"S": "Dark Roast Espresso"},
  "price": {"SS": ["280.000 VND", "420.000 VND"]},
  "sizes": {"SS": ["8OZ", "12OZ"]},
  "note": {"S": "Bold and intense flavor, perfect for espresso lovers."},
  "imageUrl": {"S": "https://example.com/image3.jpg"},
  "createdAt": {"N": "1707523200000"},
  "updatedAt": {"N": "1707523200000"}
}
```

**Product 4**:
```json
{
  "productId": {"S": "prod-004"},
  "nameProduct": {"S": "Honey Process Arabica"},
  "price": {"SS": ["400.000 VND", "550.000 VND"]},
  "sizes": {"SS": ["8OZ", "12OZ"]},
  "note": {"S": "Sweet honey notes with caramel undertones."},
  "imageUrl": {"S": "https://example.com/image4.jpg"},
  "createdAt": {"N": "1707523200000"},
  "updatedAt": {"N": "1707523200000"}
}
```

**Lưu ý**: Khi query bằng DocumentClient trong Lambda, data sẽ được tự động convert về JavaScript objects (không có type annotations), nên bạn sẽ nhận được:
```javascript
{
  productId: "prod-001",
  nameProduct: "Default Route Coffee",
  price: ["300.000 VND", "450.000 VND"],  // SS → Array
  sizes: ["8OZ", "12OZ"],
  // ...
}
```

---

## BƯỚC 1.2: TẠO IAM ROLE CHO LAMBDA

### 📚 Lý thuyết: IAM Role là gì?

**Tài liệu tham khảo**: [AWS IAM Roles](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html)

**IAM (Identity and Access Management)** quản lý quyền truy cập AWS resources.

**IAM Role** là một identity có specific permissions, không gắn với 1 user cụ thể mà được "assume" bởi services (như Lambda, EC2).

**Tại sao Lambda cần IAM Role?**
- Lambda function cần quyền để:
  - Read/Write DynamoDB
  - Write logs vào CloudWatch
  - Access S3, SES, etc.

**Principle of Least Privilege**: Chỉ cấp quyền tối thiểu cần thiết.

**Tài liệu**: [Lambda Execution Role](https://docs.aws.amazon.com/lambda/latest/dg/lambda-intro-execution-role.html)

---

### 🔨 Thực hành: Tạo IAM Role

**Bước 1**: Truy cập IAM Console

1. AWS Console → Search "IAM"
2. Click **IAM** (Identity and Access Management)

**Bước 2**: Tạo Policy trước

1. Sidebar → Click **Policies**
2. Click **Create policy**
3. Chọn tab **JSON**
4. Paste policy sau:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DynamoDBAccess",
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:Query",
        "dynamodb:Scan"
      ],
      "Resource": [
        "arn:aws:dynamodb:ap-southeast-1:*:table/Coffee*",
        "arn:aws:dynamodb:ap-southeast-1:*:table/Coffee*/index/*"
      ]
    },
    {
      "Sid": "CloudWatchLogsAccess",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:ap-southeast-1:*:*"
    }
  ]
}
```

**Giải thích từng phần**:

- **Version**: Version của policy language (luôn là "2012-10-17")
- **Statement**: Mảng các permissions
- **Sid**: Statement ID (tên để identify statement)
- **Effect**: "Allow" (cho phép) hoặc "Deny" (từ chối)
- **Action**: Các hành động được phép (ví dụ: dynamodb:GetItem)
- **Resource**: AWS resources áp dụng policy (dùng ARN - Amazon Resource Name)

**Chi tiết Resource ARN**:
```
arn:aws:dynamodb:ap-southeast-1:*:table/Coffee*
```
- `arn:aws`: ARN format
- `dynamodb`: Service
- `ap-southeast-1`: Region
- `*`: Account ID (wildcard - áp dụng cho account hiện tại)
- `table/Coffee*`: Tất cả tables bắt đầu bằng "Coffee"

5. Click **Next**
6. **Policy name**: `CoffeeLambdaPolicy`
7. **Description**: `Permissions for Coffee Shop Lambda functions`
8. Click **Create policy**

**Bước 3**: Tạo Role và attach Policy

1. Sidebar → Click **Roles**
2. Click **Create role**
3. **Trusted entity type**: 
   - Chọn **AWS service**
   - **Use case**: Lambda
   - Click **Next**

**Giải thích Trusted Entity**:
- Xác định "ai" có thể assume role này
- Chọn "AWS service" → Lambda nghĩa là chỉ Lambda service mới có thể dùng role này

4. **Add permissions**:
   - Search và check ☑ `CoffeeLambdaPolicy` (vừa tạo)
   - Click **Next**

5. **Role details**:
   - **Role name**: `CoffeeLambdaExecutionRole`
   - **Description**: `Execution role for Coffee Shop Lambda functions`
   - Click **Create role**

6. Verify role đã tạo:
   - Tìm role vừa tạo trong danh sách
   - Click vào → Tab **Trust relationships** → Verify có lambda.amazonaws.com

---

## BƯỚC 1.3: TẠO LAMBDA FUNCTION - GET PRODUCTS

### 📚 Lý thuyết: AWS Lambda là gì?

**Tài liệu tham khảo**: [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/latest/dg/welcome.html)

**AWS Lambda** là serverless compute service cho phép chạy code mà không cần quản lý servers.

**Các khái niệm quan trọng**:

1. **Function**: Một đơn vị code xử lý logic
2. **Runtime**: Môi trường chạy code (Node.js, Python, Java, etc.)
3. **Handler**: Entry point của function (hàm được gọi đầu tiên)
4. **Event**: Input data được truyền vào function
5. **Context**: Runtime information về function execution
6. **Timeout**: Thời gian tối đa function được chạy (default 3s, max 15 minutes)
7. **Memory**: RAM allocated cho function (128MB - 10GB)

**Lambda Pricing**:
- **Free tier**: 1M requests/month + 400,000 GB-seconds compute time
- Sau đó: $0.20 per 1M requests + compute time based on memory

**Tài liệu**: [Lambda Programming Model](https://docs.aws.amazon.com/lambda/latest/dg/foundation-progmodel.html)

---

### 🔨 Thực hành: Tạo Lambda Function

**Bước 1**: Truy cập Lambda Console

1. AWS Console → Search "Lambda"
2. Click **Lambda**
3. Đảm bảo region = ap-southeast-1

**Bước 2**: Tạo Function mới

1. Click **Create function**
2. Chọn **Author from scratch** (tạo từ đầu)
3. **Function name**: `coffee-get-products`

**Naming convention**: 
- Prefix: `coffee-` (project name)
- Action: `get-products` (động từ + noun)
- Lowercase, dấu gạch ngang

4. **Runtime**: Node.js 20.x

**Giải thích Runtime**:
- Node.js 20.x là version mới nhất (tính đến 2026)
- Hỗ trợ ES6+ features
- Performance tốt hơn versions cũ

5. **Architecture**: x86_64 (default)

6. **Permissions**:
   - Expand **Change default execution role**
   - Chọn **Use an existing role**
   - **Existing role**: `CoffeeLambdaExecutionRole`

7. Click **Create function**

**Bước 3**: Configure Lambda để dùng ES Modules

**📚 Lý thuyết: ES Modules trong Node.js Lambda**

**Tài liệu**: [Using ES Modules in Lambda](https://docs.aws.amazon.com/lambda/latest/dg/nodejs-handler.html#nodejs-handler-esmodules)

**ES Modules vs CommonJS**:

| Feature | CommonJS | ES Modules |
|---------|----------|------------|
| **Syntax** | `require()` / `module.exports` | `import` / `export` |
| **Loading** | Synchronous | Asynchronous |
| **Tree shaking** | ❌ | ✅ |
| **Modern** | Old standard | New standard (ES6+) |
| **Lambda support** | Default | Node.js 14+ |

**CommonJS (cũ)**:
```javascript
const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
exports.handler = async (event) => { ... };
```

**ES Modules (mới)**:
```javascript
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
export const handler = async (event) => { ... };
```

**Ưu điểm ES Modules**:
- ✅ Syntax hiện đại, clean hơn
- ✅ Tree shaking → Bundle size nhỏ hơn
- ✅ Top-level await support
- ✅ Static analysis tốt hơn
- ✅ Future-proof (industry standard)

**Để enable ES Modules trong Lambda**:

1. Trong Lambda console, tab **Code source**
2. Click **File** → **New File**
3. Tên file: `package.json`
4. Paste content:

```json
{
  "type": "module"
}
```

5. Click **File** → **Save**

**Giải thích**: `"type": "module"` báo cho Node.js biết đây là ES Module project.

---

**Bước 4**: Viết code Lambda với ES Modules

1. Click vào file **index.mjs** (hoặc tạo mới nếu chưa có)
   - **Lưu ý**: ES Modules dùng extension `.mjs` hoặc `.js` (nếu có package.json)

2. Xóa code mặc định
3. Paste code sau:

```javascript
// Import AWS SDK v3 với ES Modules
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, ScanCommand } from "@aws-sdk/lib-dynamodb";

// Khởi tạo DynamoDB client (outside handler để reuse)
const client = new DynamoDBClient({ region: "ap-southeast-1" });
const docClient = DynamoDBDocumentClient.from(client);

/**
 * Lambda handler function
 * @param {Object} event - API Gateway event object
 * @param {Object} context - Lambda context object
 * @returns {Object} Response object với statusCode, headers, body
 */
export const handler = async (event, context) => {
  console.log("Event received:", JSON.stringify(event, null, 2));
  
  try {
    // Scan DynamoDB table để lấy tất cả products
    const result = await docClient.send(
      new ScanCommand({
        TableName: "CoffeeProducts",
      })
    );

    console.log("Products fetched:", result.Items?.length || 0);

    // Return response theo format API Gateway Lambda Proxy Integration
    return {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*", // CORS
        "Access-Control-Allow-Headers": "*",
        "Access-Control-Allow-Methods": "GET, OPTIONS"
      },
      body: JSON.stringify({
        message: "Products fetched successfully",
        products: result.Items || [],
        count: result.Items?.length || 0
      }),
    };
  } catch (error) {
    console.error("Error fetching products:", error);
    
    return {
      statusCode: 500,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify({
        message: "Error fetching products",
        error: error.message
      }),
    };
  }
};
```

**Giải thích code chi tiết**:

**1. Import với ES Modules**:
```javascript
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, ScanCommand } from "@aws-sdk/lib-dynamodb";
```
- **Syntax**: `import { Named } from "package"` thay vì `require()`
- **Modular**: Chỉ import những gì cần → Smaller bundle
- `DynamoDBClient`: Low-level client (làm việc với format có type annotations)
- `DynamoDBDocumentClient`: High-level client, **tự động convert** giữa JavaScript objects ↔ DynamoDB JSON
- `ScanCommand`: Command để scan toàn bộ table

**2. Khởi tạo client outside handler**:
```javascript
const client = new DynamoDBClient({ region: "ap-southeast-1" });
const docClient = DynamoDBDocumentClient.from(client);
```
- **Optimization**: Tạo client outside handler → Reuse giữa các invocations (Lambda container reuse)
- **region**: Phải match với region của DynamoDB table
- **DocumentClient.from()**: Wrap low-level client với high-level DocumentClient

**Lý do dùng DocumentClient**:
- ✅ Tự động convert types: `{"S": "value"}` → `"value"`
- ✅ Code đơn giản hơn
- ✅ Dễ debug và maintain

**3. Handler export với ES Modules**:
```javascript
export const handler = async (event, context) => {
```
- **Syntax**: `export const handler` thay vì `exports.handler`
- **async**: Dùng async/await cho asynchronous operations
- **event**: Object chứa request data từ API Gateway (httpMethod, path, headers, body, queryStringParameters, etc.)
- **context**: Runtime info (requestId, functionName, memoryLimit, etc.) - không dùng trong code này

**4. Scan DynamoDB**:
```javascript
const result = await docClient.send(
  new ScanCommand({
    TableName: "CoffeeProducts",
  })
);
```
- **ScanCommand**: Read **tất cả items** trong table (full table scan)
- **Lưu ý**: Scan expensive cho large tables (consume nhiều Read Capacity Units)
  - Nên dùng Query nếu có thể (với partition key hoặc index)
  - Hoặc Scan với FilterExpression, Limit để giảm cost
- **result.Items**: Array of products (JavaScript objects, không có type annotations nhờ DocumentClient)

**5. Response format (Lambda Proxy Integration)**:
```javascript
return {
  statusCode: 200,
  headers: { ... },
  body: JSON.stringify({ ... }),
};
```
- **statusCode**: HTTP status code (200 = OK, 500 = Internal Server Error)
- **headers**: HTTP response headers, bao gồm CORS headers
- **body**: Response payload, **MUST be string** (dùng JSON.stringify)

**CORS Headers** (quan trọng!):
```javascript
"Access-Control-Allow-Origin": "*"  // Cho phép mọi origins
"Access-Control-Allow-Headers": "*"  // Cho phép mọi headers
"Access-Control-Allow-Methods": "GET, OPTIONS"  // Cho phép GET và OPTIONS methods
```
- **Tại sao cần CORS**: Frontend (localhost:5173) và API (execute-api.amazonaws.com) khác origin → Browser block request nếu không có CORS headers
- **Production**: Nên restrict origin thay vì `"*"`, ví dụ: `"https://yourdomain.com"`

**6. Error handling**:
```javascript
catch (error) {
  console.error("Error fetching products:", error);
  return {
    statusCode: 500,
    headers: { "Access-Control-Allow-Origin": "*" },
    body: JSON.stringify({ message: "Error...", error: error.message })
  };
}
```
- Log error vào CloudWatch Logs để debug
- Return 500 status code
- **Vẫn phải có CORS headers** trong error response

4. Click **Deploy** (nút màu cam) để save code

**Bước 5**: Update Handler configuration

1. Scroll lên trên, phần **Runtime settings**
2. Click **Edit**
3. **Handler**: Đổi thành `index.handler`
   - Format: `<filename>.<export_name>`
   - `index` = file index.mjs (không có extension)
   - `handler` = exported function name
4. Click **Save**

**Bước 6**: Configure Function settings

1. Tab **Configuration** → **General configuration**
2. Click **Edit**
3. Thay đổi:
   - **Timeout**: 30 seconds (từ 3s default)
   - **Memory**: 128 MB (giữ nguyên)

**Giải thích**:
- **Timeout 30s**: Đủ cho DynamoDB operations (Scan có thể mất vài giây)
- **Memory 128 MB**: Tối thiểu, đủ cho function đơn giản này
- **Trade-off**: Memory càng cao → CPU power càng nhiều → Chạy nhanh hơn nhưng cost cao hơn
- **Best practice**: Start với 128 MB, monitor performance, scale nếu cần

4. Click **Save**

**Bước 7**: Test Lambda Function

1. Tab **Test** 
2. Click **Create new test event**
3. **Event name**: `testGetProducts`
4. **Template**: API Gateway AWS Proxy
5. Giữ nguyên JSON (event mẫu từ API Gateway)
6. Click **Save**
7. Click **Test**

**Kết quả mong đợi**:
- **Execution result**: succeeded
- **Response**:
  ```json
  {
    "statusCode": 200,
    "headers": { ... },
    "body": "{\"message\":\"Products fetched successfully\",\"products\":[...],\"count\":4}"
  }
  ```

8. Expand **Details** để xem logs và duration

---

## BƯỚC 1.4: TẠO API GATEWAY - GET /PRODUCTS

### 📚 Lý thuyết: API Gateway là gì?

**Tài liệu tham khảo**: [Amazon API Gateway Documentation](https://docs.aws.amazon.com/apigateway/latest/developerguide/welcome.html)

**Amazon API Gateway** là fully managed service để tạo, publish, maintain, monitor, và secure APIs.

**Các loại API**:
1. **REST API**: Traditional RESTful APIs
2. **HTTP API**: Simpler, cheaper version của REST API
3. **WebSocket API**: For real-time two-way communication

**Chúng ta dùng REST API** vì:
- Feature-rich (authorizers, request validation, caching)
- Industry standard
- Phù hợp cho project này

**Các khái niệm quan trọng**:

1. **API**: Container cho các resources và methods
2. **Resource**: URL path (ví dụ: /products, /orders)
3. **Method**: HTTP method (GET, POST, PUT, DELETE)
4. **Integration**: Backend service mà API gọi đến (Lambda, HTTP endpoint, AWS service)
5. **Stage**: Môi trường deploy (dev, test, prod)
6. **Deployment**: Snapshot của API configuration

**Tài liệu**: [REST API Concepts](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-vs-rest.html)

---

### 📖 Lý thuyết: Lambda Proxy Integration

**Tài liệu tham khảo**: [Lambda Proxy Integration](https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html)

**Lambda Proxy Integration** là integration type giữa API Gateway và Lambda, nơi:

**Request Flow**:
```
Client → API Gateway → Lambda (receives raw event) → Process → Return response → API Gateway → Client
```

**Đặc điểm**:
- API Gateway **truyền toàn bộ request** (headers, body, query params, etc.) vào Lambda event
- Lambda **phải tự xử lý** và return đúng format response
- API Gateway chỉ forward, không transform data

**Event object mà Lambda nhận**:
```json
{
  "httpMethod": "GET",
  "path": "/products",
  "queryStringParameters": { "category": "coffee" },
  "headers": { "Content-Type": "application/json" },
  "body": null
}
```

**Response mà Lambda phải return**:
```json
{
  "statusCode": 200,
  "headers": { "Content-Type": "application/json" },
  "body": "{\"message\":\"success\"}"
}
```

**Ưu điểm**:
- ✅ Linh hoạt: Lambda control toàn bộ response
- ✅ Đơn giản: Không cần config mapping templates
- ✅ Industry standard: Dùng nhiều nhất

**Nhược điểm**:
- ❌ Lambda phải handle nhiều logic hơn (validation, error handling)

**So sánh với Non-Proxy Integration**:
- **Non-Proxy**: API Gateway transform request/response theo mapping templates
- **Proxy**: API Gateway forward trực tiếp, Lambda tự xử lý

**Khi nào dùng Proxy?**
- Hầu hết các trường hợp (recommended)
- Khi muốn Lambda có full control
- Khi backend là microservices

---

### 🔨 Thực hành: Tạo API Gateway

**Bước 1**: Truy cập API Gateway Console

1. AWS Console → Search "API Gateway"
2. Click **API Gateway**
3. Đảm bảo region = ap-southeast-1

**Bước 2**: Tạo REST API

1. Click **Create API**
2. Tìm **REST API** (KHÔNG phải REST API Private)
3. Click **Build**

**Giải thích các options**:
- **REST API**: Standard, feature-rich
- **HTTP API**: Simpler, cheaper (nhưng ít features)
- **WebSocket API**: Real-time communication
- **REST API Private**: Chỉ access trong VPC

4. **Choose the protocol**:
   - Chọn **REST** (default)

5. **Create new API**:
   - Chọn **New API** (create từ đầu)

6. **Settings**:
   - **API name**: `CoffeeShopAPI`
   - **Description**: `API for Coffee Shop E-commerce`
   - **Endpoint Type**: Regional

**Giải thích Endpoint Types**:
- **Regional**: Deployed in specified region (chọn cái này)
  - Use case: Serve users in specific region (Asia)
  - Performance: Low latency for nearby users
- **Edge Optimized**: Distributed via CloudFront (global)
  - Use case: Serve global users
  - Performance: Low latency worldwide, nhưng phức tạp hơn
- **Private**: Chỉ access trong VPC
  - Use case: Internal APIs

**Tài liệu**: [API Endpoint Types](https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-api-endpoint-types.html)

7. Click **Create API**

**Bước 3**: Tạo Resource /products

1. API vừa tạo sẽ có root resource `/`
2. **Actions** → **Create Resource**

**Giải thích Resource**:
- Resource = URL path segment
- Có thể nested: `/products/{productId}`, `/users/{userId}/orders`

3. **Resource configuration**:
   - **Resource Name**: `products`
   - **Resource Path**: `/products` (auto-generated)
   - **Enable API Gateway CORS**: ☑ CHECK (quan trọng!)

**Giải thích CORS**:

**CORS (Cross-Origin Resource Sharing)** là cơ chế bảo mật browser.

**Vấn đề**:
- Frontend chạy ở `http://localhost:5173`
- Backend API ở `https://xxx.execute-api.amazonaws.com`
- Khác origin → Browser block request

**Giải pháp**: CORS headers
```javascript
"Access-Control-Allow-Origin": "*"  // Cho phép mọi origin
"Access-Control-Allow-Methods": "GET,POST"  // Cho phép methods
"Access-Control-Allow-Headers": "Content-Type"  // Cho phép headers
```

**Tài liệu**: [CORS Documentation](https://docs.aws.amazon.com/apigateway/latest/developerguide/how-to-cors.html)

4. Click **Create Resource**

**Bước 4**: Tạo GET Method

1. Click chọn resource `/products` (highlight màu xanh)
2. **Actions** → **Create Method**
3. Dropdown xuất hiện → Chọn **GET**
4. Click ✓ (checkmark) để confirm

5. **Setup GET Method**:
   - **Integration type**: Lambda Function
   - **Use Lambda Proxy integration**: ☑ CHECK (quan trọng!)
   - **Lambda Region**: ap-southeast-1
   - **Lambda Function**: `coffee-get-products` (gõ để search)
   - **Use Default Timeout**: ☑ (29 seconds)

**Giải thích**:
- **Lambda Proxy integration**: Đã giải thích ở phần lý thuyết trên
- **Default Timeout 29s**: API Gateway timeout (max = 29s)

6. Click **Save**
7. Popup xuất hiện: "Add Permission to Lambda Function"
   - Click **OK**

**Giải thích Permission**:
- API Gateway cần permission để invoke Lambda
- AWS tự động thêm resource-based policy vào Lambda

**Bước 5**: Enable CORS cho method

Mặc dù đã enable CORS khi tạo resource, nhưng cần enable thêm cho method:

1. Click chọn resource `/products`
2. **Actions** → **Enable CORS**
3. **Gateway Responses for /products**:
   - Giữ nguyên default settings
   - **Access-Control-Allow-Methods**: GET, OPTIONS (checked)
   - **Access-Control-Allow-Headers**: Giữ default
   - **Access-Control-Allow-Origin**: `*`

4. Click **Enable CORS and replace existing CORS headers**
5. Confirm: **Yes, replace existing values**

**Giải thích OPTIONS method**:
- Browser tự động gửi **preflight request** (OPTIONS method) trước GET/POST
- OPTIONS method return CORS headers
- Browser check headers → Nếu OK → Gửi actual request

**Tài liệu**: [CORS Preflight](https://developer.mozilla.org/en-US/docs/Glossary/Preflight_request)

---

**Bước 6**: Test API trong Console

1. Click vào method **GET** (màu xanh)
2. Click **TEST** (icon lightning bolt)
3. Scroll xuống → Click **Test**

**Kết quả mong đợi**:
- **Status**: 200
- **Response Body**:
  ```json
  {
    "message": "Products fetched successfully",
    "products": [...],
    "count": 4
  }
  ```
- **Logs**: Hiển thị execution logs

**Nếu lỗi**:
- Check Lambda function có test OK không
- Check IAM role có permissions DynamoDB không
- Check CloudWatch Logs

---

**Bước 7**: Deploy API

**Lý thuyết**: Deploy là gì?

API Gateway cần **deploy** để changes có hiệu lực:
- Changes trong console = draft
- Deploy = tạo snapshot và đẩy lên stage

**Stage** là môi trường (dev, test, prod) với URL riêng.

1. **Actions** → **Deploy API**
2. **Deployment stage**: [New Stage]
3. **Stage name**: `prod`
   - Tên stage = part of URL

4. **Stage description**: `Production environment`
5. Click **Deploy**

**Kết quả**:
- URL xuất hiện: `https://xxxxxxxx.execute-api.ap-southeast-1.amazonaws.com/prod`
- Copy URL này để dùng

**Bước 8**: Test API với cURL

```bash
curl https://YOUR-API-ID.execute-api.ap-southeast-1.amazonaws.com/prod/products
```

**Thay `YOUR-API-ID`** bằng API ID thực tế.

**Kết quả mong đợi**:
```json
{
  "message": "Products fetched successfully",
  "products": [
    {
      "productId": "prod-001",
      "nameProduct": "Default Route Coffee",
      ...
    }
  ],
  "count": 4
}
```

**Bước 9**: Update Frontend Config

1. Mở file `src/config/api.config.js`
2. Update:

```javascript
const API_CONFIG = {
  BASE_URL: 'https://YOUR-API-ID.execute-api.ap-southeast-1.amazonaws.com/prod',
  // ...
};
```

3. Save file
4. Test trong browser → Xem products load từ AWS!

---

## ✅ CHECKPOINT 1: HOÀN THÀNH CHỨC NĂNG XEM SẢN PHẨM

### 🎉 Chúc mừng! Bạn đã hoàn thành:

- ✅ Tạo DynamoDB table: CoffeeProducts
- ✅ Tạo IAM role: CoffeeLambdaExecutionRole
- ✅ Tạo Lambda function: coffee-get-products
- ✅ Tạo API Gateway: CoffeeShopAPI
- ✅ Tạo resource: /products
- ✅ Tạo method: GET /products
- ✅ Test API thành công

### 📚 Kiến thức đã học:

- **DynamoDB**: NoSQL database, partition key, scan operation
- **IAM**: Roles, policies, permissions
- **Lambda**: Serverless functions, handler, event/context, AWS SDK
- **API Gateway**: REST API, resources, methods, stages, deployment
- **Lambda Proxy Integration**: Event passthrough, response format
- **CORS**: Cross-origin requests, preflight, headers

### 🔍 Troubleshooting:

**Lỗi "Access Denied"**:
- Check IAM role có attach policy không
- Check policy có correct permissions không

**Lỗi CORS**:
- Check đã enable CORS cho resource và method
- Check Lambda return CORS headers
- Check OPTIONS method exist

**Lỗi "Internal Server Error"**:
- Check Lambda logs trong CloudWatch
- Check DynamoDB table name đúng không
- Check region đúng không

---

## 🧪 LAB 2: TẠO ĐƠN HÀNG (POST /ORDERS)

### 📖 Lý thuyết: Tại sao LAB 2 quan trọng?

LAB này sẽ dạy bạn:
- Tạo table với **Global Secondary Index (GSI)**
- Lambda function với **POST method** và **request body parsing**
- **Data validation** và error handling
- **Write operations** trong DynamoDB (PutItem)
- **ID generation** (UUID)

---

## BƯỚC 2.1: TẠO DYNAMODB TABLE - COFFEEORDERS

### 📚 Lý thuyết: Global Secondary Index (GSI)

**Tài liệu tham khảo**: [Global Secondary Indexes](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/GSI.html)

**Vấn đề**: DynamoDB chỉ cho phép query theo Partition Key (và Sort Key nếu có). Nếu muốn query theo attribute khác sao?

**Ví dụ**:
- Table **CoffeeOrders** có partition key = `orderId`
- Muốn query: "Lấy tất cả orders của user X" → Không thể query theo `userId` trực tiếp!

**Giải pháp**: Global Secondary Index (GSI)

**GSI** là một index độc lập với:
- **Partition Key riêng** (ví dụ: userId)
- **Sort Key riêng** (optional, ví dụ: createdAt)
- **Projected attributes**: Attributes được copy vào index

**Cách hoạt động**:
1. Tạo table với primary key: `orderId`
2. Tạo GSI với partition key: `userId`, sort key: `createdAt`
3. Khi insert order → DynamoDB tự động update GSI
4. Query GSI để lấy orders by userId

**Ví dụ query**:
```javascript
// Query by orderId (primary key)
await docClient.send(new GetCommand({
  TableName: "CoffeeOrders",
  Key: { orderId: "order-001" }
}));

// Query by userId (GSI)
await docClient.send(new QueryCommand({
  TableName: "CoffeeOrders",
  IndexName: "UserIdIndex",
  KeyConditionExpression: "userId = :userId",
  ExpressionAttributeValues: { ":userId": "user-123" }
}));
```

**Local Secondary Index (LSI) vs Global Secondary Index (GSI)**:

| Feature | LSI | GSI |
|---------|-----|-----|
| **Partition key** | Same as table | Different |
| **Sort key** | Different | Different (optional) |
| **RCU/WCU** | Share with table | Separate |
| **Creation** | Only at table creation | Anytime |
| **Limit** | 5 per table | 20 per table |

**Khi nào dùng GSI**:
- ✅ Query theo attribute khác ngoài primary key
- ✅ Query patterns khác nhau (ví dụ: by userId, by status, by date)
- ✅ Separate throughput capacity

**Tài liệu**: [GSI Best Practices](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/bp-indexes-general.html)

---

### 🔨 Thực hành: Tạo bảng CoffeeOrders với GSI

**Bước 1**: Truy cập DynamoDB Console

1. AWS Console → DynamoDB
2. Region: ap-southeast-1
3. Click **Create table**

**Bước 2**: Table configuration

```
Table name: CoffeeOrders
```

```
Partition key: orderId (String)
```

**Giải thích**: 
- `orderId` unique cho mỗi order
- Format: `order-<timestamp>-<random>` (sẽ generate trong Lambda)

```
Sort key: - None -
```

**Lý do không dùng sort key**: 
- Mỗi order có 1 record duy nhất
- Không cần sort orders by orderId

```
Table settings: On-demand
```

**Bước 3**: Tạo Global Secondary Index

1. Scroll xuống **Secondary indexes**
2. Click **Create global index**

3. **Index configuration**:
   - **Partition key**: `userId` (String)
   - **Sort key**: `createdAt` (Number)
   - **Index name**: `UserIdIndex` (auto-generated, có thể giữ nguyên)
   - **Attribute projections**: All

**Giải thích**:
- **userId**: Để query "orders của user X"
- **createdAt**: Để sort orders theo thời gian (mới nhất → cũ nhất)
- **Projections = All**: Copy tất cả attributes vào index (dễ dùng, nhưng tốn storage)
  - **Keys only**: Chỉ copy keys (tiết kiệm storage)
  - **Include**: Chọn specific attributes
  - **All**: Copy tất cả (recommended cho đơn giản)

4. Click **Create index**

**Bước 4**: Hoàn tất tạo table

1. Scroll xuống, giữ nguyên settings khác
2. Click **Create table**
3. Đợi table được tạo (status: Active)

**Bước 5**: Verify GSI

1. Click vào table **CoffeeOrders**
2. Tab **Indexes**
3. Xem index **UserIdIndex**:
   - Partition key: userId
   - Sort key: createdAt
   - Status: Active

**Bước 6**: Thêm sample order (optional)

1. Tab **Explore table items**
2. Click **Create item**
3. JSON view, paste:

```json
{
  "orderId": {"S": "order-1707523200000-abc123"},
  "userId": {"S": "user-001"},
  "customerName": {"S": "Nguyen Van A"},
  "email": {"S": "nguyenvana@example.com"},
  "phone": {"S": "0901234567"},
  "address": {"S": "123 Le Loi, Q1, TPHCM"},
  "items": {"L": [
    {"M": {
      "productId": {"S": "prod-001"},
      "nameProduct": {"S": "Default Route Coffee"},
      "size": {"S": "12OZ"},
      "price": {"S": "450.000 VND"},
      "quantity": {"N": "2"}
    }}
  ]},
  "totalAmount": {"S": "900.000 VND"},
  "status": {"S": "pending"},
  "createdAt": {"N": "1707523200000"},
  "updatedAt": {"N": "1707523200000"}
}
```

**Giải thích types**:
- `{"L": [...]}` = List type (array)
- `{"M": {...}}` = Map type (nested object)
- `items` là List of Maps (array of objects)

4. Click **Create item**

---

## BƯỚC 2.2: TẠO LAMBDA FUNCTION - CREATE ORDER

### 📚 Lý thuyết: UUID và ID Generation

**Tài liệu tham khảo**: [UUID Standard](https://datatracker.ietf.org/doc/html/rfc4122)

**UUID (Universally Unique Identifier)** là standard để generate unique IDs.

**Tại sao cần UUID**:
- ❌ **Không dùng**: Auto-increment (1, 2, 3...) → Không phù hợp cho distributed systems
- ❌ **Không dùng**: Timestamp alone → Có thể duplicate nếu 2 requests cùng millisecond
- ✅ **Dùng**: UUID v4 → Practically unique (collision probability ≈ 0)

**UUID v4 format**: `550e8400-e29b-41d4-a716-446655440000`
- 36 characters (32 hex + 4 hyphens)
- Random generation

**Node.js built-in crypto module** (Node 14.17+):
```javascript
import { randomUUID } from 'crypto';
const id = randomUUID(); // "550e8400-e29b-41d4-a716-446655440000"
```

**Hybrid approach** (UUID + timestamp):
```javascript
const orderId = `order-${Date.now()}-${randomUUID().split('-')[0]}`;
// "order-1707523200000-550e8400"
```
- Readable (có timestamp)
- Sortable (sort by creation time)
- Unique (có UUID portion)

---

### 🔨 Thực hành: Tạo Lambda Function

**Bước 1**: Tạo Function

1. Lambda Console → **Create function**
2. **Function name**: `coffee-create-order`
3. **Runtime**: Node.js 20.x
4. **Architecture**: x86_64
5. **Execution role**: Use existing role `CoffeeLambdaExecutionRole`
6. Click **Create function**

**Bước 2**: Configure ES Modules

1. Tab **Code source**
2. Tạo file `package.json`:

```json
{
  "type": "module"
}
```

3. Click **File** → **Save**

**Bước 3**: Viết code Lambda

1. Click file `index.mjs`
2. Paste code:

```javascript
// Import AWS SDK v3
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, PutCommand } from "@aws-sdk/lib-dynamodb";
import { randomUUID } from 'crypto';

// Khởi tạo DynamoDB client
const client = new DynamoDBClient({ region: "ap-southeast-1" });
const docClient = DynamoDBDocumentClient.from(client);

/**
 * Lambda handler - Create new order
 * @param {Object} event - API Gateway event
 * @returns {Object} Response
 */
export const handler = async (event) => {
  console.log("Event:", JSON.stringify(event, null, 2));
  
  try {
    // Parse request body
    const body = JSON.parse(event.body || '{}');
    console.log("Order data:", body);
    
    // Validate required fields
    const requiredFields = ['customerName', 'email', 'phone', 'address', 'items'];
    for (const field of requiredFields) {
      if (!body[field]) {
        return {
          statusCode: 400,
          headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*"
          },
          body: JSON.stringify({
            message: `Missing required field: ${field}`
          })
        };
      }
    }
    
    // Validate items array
    if (!Array.isArray(body.items) || body.items.length === 0) {
      return {
        statusCode: 400,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*"
        },
        body: JSON.stringify({
          message: "Items must be a non-empty array"
        })
      };
    }
    
    // Generate unique order ID
    const timestamp = Date.now();
    const uuid = randomUUID().split('-')[0]; // First segment of UUID
    const orderId = `order-${timestamp}-${uuid}`;
    
    // Prepare order object
    const order = {
      orderId,
      userId: body.userId || 'guest', // userId for GSI query
      customerName: body.customerName,
      email: body.email,
      phone: body.phone,
      address: body.address,
      items: body.items, // Array of {productId, nameProduct, size, price, quantity}
      totalAmount: body.totalAmount,
      status: 'pending',
      createdAt: timestamp,
      updatedAt: timestamp
    };
    
    // Save to DynamoDB
    await docClient.send(
      new PutCommand({
        TableName: "CoffeeOrders",
        Item: order
      })
    );
    
    console.log("Order created:", orderId);
    
    // Return success response
    return {
      statusCode: 201,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS"
      },
      body: JSON.stringify({
        message: "Order created successfully",
        order
      })
    };
    
  } catch (error) {
    console.error("Error creating order:", error);
    
    return {
      statusCode: 500,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      },
      body: JSON.stringify({
        message: "Error creating order",
        error: error.message
      })
    };
  }
};
```

**Giải thích code chi tiết**:

**1. Imports**:
```javascript
import { DynamoDBDocumentClient, PutCommand } from "@aws-sdk/lib-dynamodb";
import { randomUUID } from 'crypto';
```
- `PutCommand`: Insert/replace item trong DynamoDB
- `randomUUID`: Node.js built-in function (Node 14.17+)

**2. Parse body**:
```javascript
const body = JSON.parse(event.body || '{}');
```
- `event.body` là string (từ API Gateway)
- Phải parse thành object
- Default `'{}'` nếu body empty

**3. Validation**:
```javascript
const requiredFields = ['customerName', 'email', 'phone', 'address', 'items'];
for (const field of requiredFields) {
  if (!body[field]) {
    return { statusCode: 400, ... };
  }
}
```
- Check required fields
- Return 400 Bad Request nếu thiếu
- **Best practice**: Validate input để tránh bad data trong database

**4. Generate orderId**:
```javascript
const orderId = `order-${Date.now()}-${randomUUID().split('-')[0]}`;
```
- Format: `order-1707523200000-550e8400`
- Readable + Sortable + Unique

**5. PutCommand**:
```javascript
await docClient.send(
  new PutCommand({
    TableName: "CoffeeOrders",
    Item: order
  })
);
```
- **PutCommand**: Insert new item hoặc replace nếu key đã exist
- **Item**: JavaScript object (DocumentClient auto-convert)

**6. Return 201 Created**:
```javascript
return {
  statusCode: 201, // Created (not 200)
  body: JSON.stringify({ message: "...", order })
};
```
- HTTP 201 = Resource created successfully
- Return order object về client

3. Click **Deploy**

**Bước 4**: Update Handler

1. **Runtime settings** → **Edit**
2. **Handler**: `index.handler`
3. Click **Save**

**Bước 5**: Configure settings

1. Tab **Configuration** → **General configuration** → **Edit**
2. **Timeout**: 30 seconds
3. **Memory**: 128 MB
4. Click **Save**

**Bước 6**: Test Lambda

1. Tab **Test** → **Create new test event**
2. **Event name**: `testCreateOrder`
3. **Template**: API Gateway AWS Proxy
4. Sửa `body` field:

```json
{
  "body": "{\"customerName\":\"Nguyen Van A\",\"email\":\"test@example.com\",\"phone\":\"0901234567\",\"address\":\"123 Le Loi, Q1, TPHCM\",\"items\":[{\"productId\":\"prod-001\",\"nameProduct\":\"Coffee\",\"size\":\"12OZ\",\"price\":\"450.000 VND\",\"quantity\":2}],\"totalAmount\":\"900.000 VND\",\"userId\":\"user-001\"}",
  "resource": "/orders",
  "path": "/orders",
  "httpMethod": "POST",
  "headers": {
    "Content-Type": "application/json"
  }
}
```

5. Click **Save** → Click **Test**

**Kết quả mong đợi**:
- Status: 201
- Response body:
```json
{
  "message": "Order created successfully",
  "order": {
    "orderId": "order-1707523200000-550e8400",
    "customerName": "Nguyen Van A",
    ...
  }
}
```

6. Verify trong DynamoDB:
   - Tab **Explore table items** của CoffeeOrders
   - Xem order vừa tạo

---

## BƯỚC 2.3: TẠO API GATEWAY - POST /ORDERS

**Bước 1**: Mở API Gateway Console

1. API Gateway → API: **CoffeeShopAPI**

**Bước 2**: Tạo Resource /orders

1. Click root `/`
2. **Actions** → **Create Resource**
3. **Resource Name**: `orders`
4. **Resource Path**: `/orders`
5. **Enable API Gateway CORS**: ☑ Check
6. Click **Create Resource**

**Bước 3**: Tạo POST Method

1. Click resource `/orders`
2. **Actions** → **Create Method**
3. Dropdown: **POST**
4. Click ✓

5. **Setup**:
   - **Integration type**: Lambda Function
   - **Use Lambda Proxy integration**: ☑ Check
   - **Lambda Function**: `coffee-create-order`
   - **Use Default Timeout**: ☑
6. Click **Save** → **OK**

**Bước 4**: Enable CORS

1. Click resource `/orders`
2. **Actions** → **Enable CORS**
3. **Access-Control-Allow-Methods**: POST, OPTIONS
4. Click **Enable CORS and replace existing CORS headers**
5. Confirm

**Bước 5**: Test trong Console

1. Click method **POST**
2. Click **TEST**
3. **Request Body**:

```json
{
  "customerName": "Nguyen Van A",
  "email": "test@example.com",
  "phone": "0901234567",
  "address": "123 Le Loi, Q1, TPHCM",
  "items": [
    {
      "productId": "prod-001",
      "nameProduct": "Default Route Coffee",
      "size": "12OZ",
      "price": "450.000 VND",
      "quantity": 2
    }
  ],
  "totalAmount": "900.000 VND",
  "userId": "user-001"
}
```

4. Click **Test**

**Kết quả mong đợi**: Status 201, order created

**Bước 6**: Deploy API

1. **Actions** → **Deploy API**
2. **Deployment stage**: prod
3. Click **Deploy**

**Bước 7**: Test với cURL

```bash
curl -X POST https://YOUR-API-ID.execute-api.ap-southeast-1.amazonaws.com/prod/orders \
  -H "Content-Type: application/json" \
  -d '{
    "customerName": "Nguyen Van A",
    "email": "test@example.com",
    "phone": "0901234567",
    "address": "123 Le Loi, Q1, TPHCM",
    "items": [
      {
        "productId": "prod-001",
        "nameProduct": "Coffee",
        "size": "12OZ",
        "price": "450.000 VND",
        "quantity": 2
      }
    ],
    "totalAmount": "900.000 VND",
    "userId": "user-001"
  }'
```

---

## ✅ CHECKPOINT 2: HOÀN THÀNH CHỨC NĂNG TẠO ĐƠN HÀNG

### 🎉 Bạn đã hoàn thành:

- ✅ Tạo DynamoDB table với GSI: CoffeeOrders + UserIdIndex
- ✅ Tạo Lambda function ES Module: coffee-create-order
- ✅ Tạo API: POST /orders
- ✅ Data validation và error handling
- ✅ UUID generation
- ✅ Test thành công

### 📚 Kiến thức đã học:

- **GSI**: Query theo attribute khác ngoài primary key
- **PutCommand**: Insert item vào DynamoDB
- **UUID**: Generate unique IDs
- **Validation**: Check required fields
- **POST method**: Parse body, return 201 status

---

## 🧪 LAB 3: XEM LỊCH SỬ ĐƠN HÀNG (GET /ORDERS)

### 📖 Lý thuyết: Query vs Scan

**Tài liệu tham khảo**: [Query vs Scan](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/bp-query-scan.html)

**Scan**:
- Read **toàn bộ table**
- Expensive (consume nhiều RCU)
- Slow cho large tables
- Use case: Get all items, analytics

**Query**:
- Read items với **specific partition key**
- Fast và efficient
- Can use sort key để filter/sort
- Use case: Get items by primary key hoặc GSI

**Ví dụ**:
```javascript
// Scan: Get all orders (expensive)
const result = await docClient.send(
  new ScanCommand({ TableName: "CoffeeOrders" })
);

// Query: Get orders by userId (efficient)
const result = await docClient.send(
  new QueryCommand({
    TableName: "CoffeeOrders",
    IndexName: "UserIdIndex",
    KeyConditionExpression: "userId = :userId",
    ExpressionAttributeValues: { ":userId": "user-001" }
  })
);
```

**Best practice**: Luôn dùng Query thay vì Scan nếu có thể.

---

## BƯỚC 3.1: TẠO LAMBDA FUNCTION - GET ORDERS

**Bước 1**: Tạo Function

1. Lambda Console → **Create function**
2. **Function name**: `coffee-get-orders`
3. **Runtime**: Node.js 20.x
4. **Execution role**: `CoffeeLambdaExecutionRole`
5. Click **Create function**

**Bước 2**: Configure ES Modules

1. Tạo `package.json`:
```json
{
  "type": "module"
}
```

**Bước 3**: Viết code

```javascript
// Import AWS SDK v3
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, QueryCommand, ScanCommand } from "@aws-sdk/lib-dynamodb";

// Khởi tạo DynamoDB client
const client = new DynamoDBClient({ region: "ap-southeast-1" });
const docClient = DynamoDBDocumentClient.from(client);

/**
 * Lambda handler - Get orders
 * @param {Object} event - API Gateway event
 * @returns {Object} Response
 */
export const handler = async (event) => {
  console.log("Event:", JSON.stringify(event, null, 2));
  
  try {
    // Get userId from query parameters
    const userId = event.queryStringParameters?.userId;
    
    let result;
    
    if (userId) {
      // Query by userId using GSI
      console.log("Querying orders for userId:", userId);
      
      result = await docClient.send(
        new QueryCommand({
          TableName: "CoffeeOrders",
          IndexName: "UserIdIndex",
          KeyConditionExpression: "userId = :userId",
          ExpressionAttributeValues: {
            ":userId": userId
          },
          ScanIndexForward: false // Sort by createdAt DESC (newest first)
        })
      );
    } else {
      // No userId: Scan all orders (admin use case)
      console.log("Scanning all orders");
      
      result = await docClient.send(
        new ScanCommand({
          TableName: "CoffeeOrders"
        })
      );
    }
    
    console.log("Orders fetched:", result.Items?.length || 0);
    
    // Return response
    return {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "*",
        "Access-Control-Allow-Methods": "GET, OPTIONS"
      },
      body: JSON.stringify({
        message: "Orders fetched successfully",
        orders: result.Items || [],
        count: result.Items?.length || 0,
        userId: userId || "all"
      })
    };
    
  } catch (error) {
    console.error("Error fetching orders:", error);
    
    return {
      statusCode: 500,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      },
      body: JSON.stringify({
        message: "Error fetching orders",
        error: error.message
      })
    };
  }
};
```

**Giải thích code**:

**1. Query parameters**:
```javascript
const userId = event.queryStringParameters?.userId;
```
- `queryStringParameters`: Object chứa query params từ URL
- Ví dụ: `/orders?userId=user-001` → `{userId: "user-001"}`
- Optional chaining `?.`: Return undefined nếu không có

**2. Conditional logic**:
```javascript
if (userId) {
  // Query by userId (GSI)
} else {
  // Scan all (admin)
}
```
- Có userId → Query GSI (efficient)
- Không có userId → Scan all (admin feature)

**3. QueryCommand**:
```javascript
new QueryCommand({
  TableName: "CoffeeOrders",
  IndexName: "UserIdIndex",
  KeyConditionExpression: "userId = :userId",
  ExpressionAttributeValues: {
    ":userId": userId
  },
  ScanIndexForward: false
})
```
- **IndexName**: Specify GSI name
- **KeyConditionExpression**: Filter by partition key (userId)
- **ExpressionAttributeValues**: Values for placeholders (`:userId`)
- **ScanIndexForward**: false = DESC sort, true = ASC sort
  - Sort by sort key của GSI (createdAt)
  - false → Newest orders first

**4. ScanCommand**:
```javascript
new ScanCommand({
  TableName: "CoffeeOrders"
})
```
- Simple scan, no filters
- Return all orders

3. Click **Deploy**

**Bước 4**: Update Handler và Settings

1. **Handler**: `index.handler`
2. **Timeout**: 30 seconds
3. **Memory**: 128 MB

**Bước 5**: Test Lambda

**Test 1: Query by userId**

1. **Event name**: `testGetOrdersByUser`
2. **Template**: API Gateway AWS Proxy
3. Sửa:

```json
{
  "queryStringParameters": {
    "userId": "user-001"
  },
  "httpMethod": "GET",
  "path": "/orders"
}
```

4. Click **Test**
5. Verify: Return orders của user-001

**Test 2: Get all orders**

1. **Event name**: `testGetAllOrders`
2. Remove `queryStringParameters`:

```json
{
  "queryStringParameters": null,
  "httpMethod": "GET",
  "path": "/orders"
}
```

3. Click **Test**
4. Verify: Return all orders

---

## BƯỚC 3.2: TẠO API GATEWAY - GET /ORDERS

**Bước 1**: Tạo GET Method

1. API Gateway → CoffeeShopAPI
2. Click resource `/orders` (đã có từ LAB 2)
3. **Actions** → **Create Method**
4. Dropdown: **GET**
5. Click ✓

**Bước 2**: Setup Integration

1. **Integration type**: Lambda Function
2. **Use Lambda Proxy integration**: ☑
3. **Lambda Function**: `coffee-get-orders`
4. Click **Save** → **OK**

**Bước 3**: Enable CORS

1. Click resource `/orders`
2. **Actions** → **Enable CORS**
3. **Methods**: GET, POST, OPTIONS (all checked)
4. Click **Enable CORS and replace existing CORS headers**
5. Confirm

**Bước 4**: Test trong Console

1. Click method **GET**
2. Click **TEST**

**Test 1: With userId**
3. **Query Strings**: `userId=user-001`
4. Click **Test**
5. Verify: Return orders của user-001

**Test 2: Without userId**
3. **Query Strings**: (leave empty)
4. Click **Test**
5. Verify: Return all orders

**Bước 5**: Deploy API

1. **Actions** → **Deploy API**
2. **Stage**: prod
3. Click **Deploy**

**Bước 6**: Test với cURL

**Get orders by userId**:
```bash
curl "https://YOUR-API-ID.execute-api.ap-southeast-1.amazonaws.com/prod/orders?userId=user-001"
```

**Get all orders**:
```bash
curl "https://YOUR-API-ID.execute-api.ap-southeast-1.amazonaws.com/prod/orders"
```

**Kết quả mong đợi**:
```json
{
  "message": "Orders fetched successfully",
  "orders": [
    {
      "orderId": "order-...",
      "userId": "user-001",
      "customerName": "Nguyen Van A",
      ...
    }
  ],
  "count": 1,
  "userId": "user-001"
}
```

---

## ✅ CHECKPOINT 3: HOÀN THÀNH CHỨC NĂNG XEM ĐƠN HÀNG

### 🎉 Bạn đã hoàn thành:

- ✅ Tạo Lambda function: coffee-get-orders
- ✅ Query DynamoDB bằng GSI
- ✅ Handle query parameters
- ✅ Conditional logic (Query vs Scan)
- ✅ Tạo API: GET /orders with query params
- ✅ Test thành công

### 📚 Kiến thức đã học:

- **Query**: Efficient way to get items by key
- **GSI Query**: Query by non-primary-key attributes
- **ScanIndexForward**: Sort order control
- **Query parameters**: Access via event.queryStringParameters
- **KeyConditionExpression**: Filter syntax
- **ExpressionAttributeValues**: Bind values to placeholders

---

## 🎊 TỔNG KẾT: ĐÃ HOÀN THÀNH 3 LAB

### ✅ Backend đã có:

1. **GET /products** - Xem sản phẩm
2. **POST /orders** - Tạo đơn hàng
3. **GET /orders?userId=xxx** - Xem lịch sử đơn hàng

### 🏗️ Architecture hiện tại:

```
Client → API Gateway (CoffeeShopAPI)
           ├── GET /products → Lambda (coffee-get-products) → DynamoDB (CoffeeProducts)
           ├── POST /orders → Lambda (coffee-create-order) → DynamoDB (CoffeeOrders)
           └── GET /orders → Lambda (coffee-get-orders) → DynamoDB (CoffeeOrders/UserIdIndex)
```

### 📊 Resources đã tạo:

**DynamoDB**:
- CoffeeProducts table (partition key: productId)
- CoffeeOrders table (partition key: orderId, GSI: UserIdIndex)

**Lambda**:
- coffee-get-products (ES Module, Scan)
- coffee-create-order (ES Module, PutCommand, UUID)
- coffee-get-orders (ES Module, Query GSI)

**IAM**:
- CoffeeLambdaPolicy (DynamoDB + CloudWatch permissions)
- CoffeeLambdaExecutionRole (used by all Lambdas)

**API Gateway**:
- CoffeeShopAPI (REST API, Regional)
- Resources: /products, /orders
- Methods: GET /products, POST /orders, GET /orders
- Stage: prod

### 🚀 Bước tiếp theo (LAB 4 & 5):

- **LAB 4**: POST /auth/register - Đăng ký (bcrypt, password hashing)
- **LAB 5**: POST /auth/login - Đăng nhập (JWT tokens, authentication)

### 💡 Tips:

1. **Monitor costs**: Check AWS Billing Dashboard regularly
2. **CloudWatch Logs**: Debug bằng logs khi có lỗi
3. **API Gateway stages**: Có thể tạo dev/test stages riêng
4. **DynamoDB capacity**: Monitor RCU/WCU usage
5. **Lambda cold start**: First invocation có thể chậm (~1-2s)

---

## 🧪 LAB 4: ĐĂNG KÝ TÀI KHOẢN (POST /auth/register)

### 📖 Lý thuyết: Tại sao cần Authentication?

Authentication (xác thực) là quá trình verify identity của user. Trong e-commerce, authentication cần thiết để:
- Bảo vệ thông tin cá nhân (địa chỉ, số điện thoại, lịch sử mua hàng)
- Quản lý đơn hàng của từng user riêng biệt
- Phân quyền (customer vs admin)
- Personalization (recommendations, saved cart)

**Security là ưu tiên hàng đầu!**

---

## BƯỚC 4.1: TẠO DYNAMODB TABLE - COFFEEUSERS

### 📚 Lý thuyết: Password Security

**Tài liệu tham khảo**: [OWASP Password Storage Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html)

**❌ KHÔNG BAO GIỜ lưu plain text password!**

```javascript
// ❌ WRONG - NEVER DO THIS
{
  email: "user@example.com",
  password: "mypassword123" // Plain text - CỰC KỲ NGUY HIỂM!
}
```

**Tại sao nguy hiểm?**
- Database bị breach → Attacker có tất cả passwords
- User thường dùng password giống nhau cho nhiều sites
- Không thể "undo" một data breach

**✅ Giải pháp: Password Hashing**

**Hashing** là quá trình one-way encryption:
```
Input: "mypassword123"
↓ Hash function (bcrypt)
Output: "$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy"
```

**Đặc điểm hashing**:
- **One-way**: Không thể reverse từ hash về password gốc
- **Deterministic**: Cùng input → cùng output
- **Fast to compute, slow to crack**: Designed để chống brute force
- **Unique**: Mỗi password có hash riêng

**bcrypt - Algorithm tốt nhất cho password hashing**:

**Ưu điểm bcrypt**:
- **Adaptive**: Có cost factor (rounds) - càng cao càng secure nhưng càng chậm
- **Salt built-in**: Tự động add random salt vào hash
- **Industry standard**: Được recommend bởi OWASP, NIST
- **Resistant to rainbow tables**: Nhờ có salt

**Salt là gì?**

Salt là random string được thêm vào password trước khi hash:
```
Without salt:
"password123" → hash → "xyz789..."
"password123" → hash → "xyz789..." (giống nhau!)

With salt:
"password123" + "random1" → hash → "abc123..."
"password123" + "random2" → hash → "def456..." (khác nhau!)
```

**Lợi ích của salt**:
- Ngăn rainbow table attacks (precomputed hash tables)
- Cùng password nhưng khác hash → Attacker không biết nhiều users dùng chung password

**bcrypt rounds (cost factor)**:
```javascript
// Cost = 10 (default, recommended)
// 2^10 = 1,024 iterations
// Time: ~100ms to hash
await bcrypt.hash("password", 10);

// Cost = 12 (more secure)
// 2^12 = 4,096 iterations
// Time: ~400ms to hash
await bcrypt.hash("password", 12);
```

**Trade-off**:
- Cost thấp → Fast nhưng dễ crack
- Cost cao → Slow nhưng secure hơn
- **Recommended**: 10-12 cho production

**Verification process**:
```javascript
// Register: Hash password
const hashedPassword = await bcrypt.hash("mypassword123", 10);
// Save: "$2b$10$N9qo8u..."

// Login: Compare
const isValid = await bcrypt.compare("mypassword123", hashedPassword);
// Returns: true
```

**Tài liệu**: 
- [bcrypt npm](https://www.npmjs.com/package/bcrypt)
- [bcryptjs npm](https://www.npmjs.com/package/bcryptjs) (pure JavaScript, không cần native dependencies)

**Trong AWS Lambda**: Chúng ta sẽ dùng **bcryptjs** vì:
- Pure JavaScript (không cần compile native modules)
- Tương thích với Lambda environment
- Performance đủ tốt
- Syntax giống bcrypt

---

### 🔨 Thực hành: Tạo bảng CoffeeUsers

**Bước 1**: Truy cập DynamoDB Console

1. AWS Console → DynamoDB
2. Region: ap-southeast-1
3. Click **Create table**

**Bước 2**: Table configuration

```
Table name: CoffeeUsers
```

```
Partition key: email (String)
```

**Giải thích**:
- `email` làm partition key vì:
  - Email unique cho mỗi user
  - Login thường dùng email
  - Efficient query: "Get user by email"
- **Không dùng userId** làm primary key vì không login bằng userId

```
Sort key: - None -
```

```
Table settings: On-demand
```

**Bước 3**: Hoàn tất

1. Scroll xuống, giữ nguyên settings khác
2. Click **Create table**
3. Đợi table Active

**Bước 4**: Verify table

1. Click vào table **CoffeeUsers**
2. Tab **Overview** → Check status: Active

**Lưu ý về GSI**: 
- Table này KHÔNG cần GSI vì chỉ query by email (primary key)
- Nếu sau này cần query by userId hoặc role, có thể add GSI

---

## BƯỚC 4.2: CHUẨN BỊ LAMBDA LAYER - BCRYPTJS

### 📚 Lý thuyết: Lambda Layers

**Tài liệu tham khảo**: [AWS Lambda Layers](https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html)

**Lambda Layer** là một cách để package dependencies (libraries, custom runtimes) riêng biệt khỏi function code.

**Vấn đề**: 
- Lambda function cần external packages (bcryptjs, jsonwebtoken)
- Mỗi function phải bundle dependencies → Duplicate code
- Upload size lớn → Deploy chậm

**Giải pháp: Lambda Layer**

```
┌─────────────────────┐
│  Lambda Function    │
│  (Your code only)   │
└──────────┬──────────┘
           │ Uses
           ↓
┌─────────────────────┐
│   Lambda Layer      │
│ (Node modules:      │
│  - bcryptjs         │
│  - jsonwebtoken)    │
└─────────────────────┘
```

**Ưu điểm**:
- ✅ Share dependencies across multiple functions
- ✅ Smaller deployment packages
- ✅ Faster deployments
- ✅ Separate dependency management

**Giới hạn**:
- Max 5 layers per function
- Max 250 MB unzipped (all layers + function)
- Layer immutable sau khi publish

**Layer structure**:
```
layer.zip
└── nodejs/
    └── node_modules/
        ├── bcryptjs/
        └── jsonwebtoken/
```

**Trong Lambda**: Layers được extract vào `/opt`
```javascript
// Lambda tự động thấy packages trong layer
import bcrypt from 'bcryptjs'; // Works!
```

---

### 🔨 Thực hành: Tạo Lambda Layer cho bcryptjs

**Tùy chọn 1: Tạo Layer từ Local (Recommended)**

**Bước 1**: Tạo thư mục layer trên máy local

```powershell
# Tạo thư mục
mkdir lambda-layer-nodejs
cd lambda-layer-nodejs

# Tạo structure đúng format
mkdir -p nodejs
cd nodejs

# Install packages
npm init -y
npm install bcryptjs jsonwebtoken
```

**Giải thích structure**:
- Folder phải tên là `nodejs` (Lambda requirement)
- `node_modules` nằm trong `nodejs/`
- Sau khi zip → Lambda extract vào `/opt/nodejs/node_modules/`

**Bước 2**: Zip layer

```powershell
# Quay lại parent folder
cd ..

# Zip (Windows)
Compress-Archive -Path nodejs -DestinationPath layer.zip
```

**Lưu ý**: Zip file phải chứa folder `nodejs/`, không phải `nodejs.zip`

```
✅ Correct:
layer.zip
└── nodejs/
    └── node_modules/

❌ Wrong:
layer.zip
└── node_modules/
```

**Bước 3**: Upload lên Lambda Layer

1. AWS Console → Lambda
2. Sidebar → **Layers**
3. Click **Create layer**

4. **Layer configuration**:
   - **Name**: `coffee-node-dependencies`
   - **Description**: `bcryptjs and jsonwebtoken for Coffee Shop`
   - **Upload**: Click **Upload a .zip file** → Chọn `layer.zip`
   - **Compatible runtimes**: ☑ Node.js 20.x
   - **Compatible architectures**: ☑ x86_64

5. Click **Create**

6. **Copy Layer ARN**: 
   ```
   arn:aws:lambda:ap-southeast-1:ACCOUNT-ID:layer:coffee-node-dependencies:1
   ```
   - Save ARN này để attach vào functions

---

**Tùy chọn 2: Sử dụng public Layer (Nhanh hơn)**

Có thể search public layers của community:
```
arn:aws:lambda:ap-southeast-1:XXXX:layer:bcryptjs:1
```

**Lưu ý**: Public layers có thể không cập nhật hoặc không tin cậy. Recommended tự tạo layer.

---

## BƯỚC 4.3: TẠO LAMBDA FUNCTION - REGISTER

**Bước 1**: Tạo Function

1. Lambda Console → **Create function**
2. **Function name**: `coffee-register-user`
3. **Runtime**: Node.js 20.x
4. **Execution role**: `CoffeeLambdaExecutionRole`
5. Click **Create function**

**Bước 2**: Attach Lambda Layer

1. Scroll xuống **Layers** section
2. Click **Add a layer**
3. **Choose a layer**: 
   - **Custom layers** (nếu bạn tự tạo layer ở bước trước)
   - Chọn `coffee-node-dependencies`
   - **Version**: 1
4. Click **Add**

**Verify**: Section **Layers** hiện `coffee-node-dependencies (1)`

**Bước 3**: Configure ES Modules

1. Tab **Code source**
2. Tạo file `package.json`:

```json
{
  "type": "module"
}
```

**Bước 4**: Viết code Lambda

File `index.mjs`:

```javascript
// Import AWS SDK v3
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, GetCommand, PutCommand } from "@aws-sdk/lib-dynamodb";

// Import bcryptjs from Lambda Layer
import bcrypt from 'bcryptjs';

// Khởi tạo DynamoDB client
const client = new DynamoDBClient({ region: "ap-southeast-1" });
const docClient = DynamoDBDocumentClient.from(client);

// Constants
const SALT_ROUNDS = 10; // bcrypt cost factor

/**
 * Validate email format
 * @param {string} email 
 * @returns {boolean}
 */
const isValidEmail = (email) => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
};

/**
 * Validate password strength
 * @param {string} password 
 * @returns {object} {valid: boolean, message: string}
 */
const validatePassword = (password) => {
  if (password.length < 8) {
    return { valid: false, message: "Password must be at least 8 characters" };
  }
  if (!/[A-Z]/.test(password)) {
    return { valid: false, message: "Password must contain at least one uppercase letter" };
  }
  if (!/[a-z]/.test(password)) {
    return { valid: false, message: "Password must contain at least one lowercase letter" };
  }
  if (!/[0-9]/.test(password)) {
    return { valid: false, message: "Password must contain at least one number" };
  }
  return { valid: true };
};

/**
 * Lambda handler - Register new user
 * @param {Object} event - API Gateway event
 * @returns {Object} Response
 */
export const handler = async (event) => {
  console.log("Event:", JSON.stringify(event, null, 2));
  
  try {
    // Parse request body
    const body = JSON.parse(event.body || '{}');
    const { email, password, name, phone } = body;
    
    console.log("Registration attempt for email:", email);
    
    // Validation: Required fields
    if (!email || !password || !name) {
      return {
        statusCode: 400,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*"
        },
        body: JSON.stringify({
          message: "Missing required fields: email, password, name"
        })
      };
    }
    
    // Validation: Email format
    if (!isValidEmail(email)) {
      return {
        statusCode: 400,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*"
        },
        body: JSON.stringify({
          message: "Invalid email format"
        })
      };
    }
    
    // Validation: Password strength
    const passwordValidation = validatePassword(password);
    if (!passwordValidation.valid) {
      return {
        statusCode: 400,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*"
        },
        body: JSON.stringify({
          message: passwordValidation.message
        })
      };
    }
    
    // Check if user already exists
    const existingUser = await docClient.send(
      new GetCommand({
        TableName: "CoffeeUsers",
        Key: { email }
      })
    );
    
    if (existingUser.Item) {
      return {
        statusCode: 409, // Conflict
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*"
        },
        body: JSON.stringify({
          message: "User with this email already exists"
        })
      };
    }
    
    // Hash password with bcrypt
    console.log("Hashing password...");
    const hashedPassword = await bcrypt.hash(password, SALT_ROUNDS);
    console.log("Password hashed successfully");
    
    // Generate userId
    const timestamp = Date.now();
    const userId = `user-${timestamp}`;
    
    // Prepare user object
    const user = {
      email, // Primary key
      userId,
      name,
      phone: phone || null,
      passwordHash: hashedPassword, // Lưu hash, không phải plain text
      role: 'customer', // Default role
      createdAt: timestamp,
      updatedAt: timestamp
    };
    
    // Save to DynamoDB
    await docClient.send(
      new PutCommand({
        TableName: "CoffeeUsers",
        Item: user
      })
    );
    
    console.log("User registered successfully:", userId);
    
    // Return success (KHÔNG return password hash!)
    return {
      statusCode: 201,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS"
      },
      body: JSON.stringify({
        message: "User registered successfully",
        user: {
          userId,
          email,
          name,
          role: user.role,
          createdAt: user.createdAt
          // passwordHash KHÔNG được return về client
        }
      })
    };
    
  } catch (error) {
    console.error("Error registering user:", error);
    
    return {
      statusCode: 500,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      },
      body: JSON.stringify({
        message: "Error registering user",
        error: error.message
      })
    };
  }
};
```

**Giải thích code chi tiết**:

**1. Import bcryptjs từ Layer**:
```javascript
import bcrypt from 'bcryptjs';
```
- Lambda tự động tìm package trong `/opt/nodejs/node_modules/`
- Không cần install trong function code

**2. Email validation**:
```javascript
const isValidEmail = (email) => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
};
```
- Regex kiểm tra format email cơ bản
- Production: có thể dùng libraries như `validator.js`

**3. Password validation**:
```javascript
const validatePassword = (password) => {
  if (password.length < 8) return { valid: false, ... };
  if (!/[A-Z]/.test(password)) return { valid: false, ... };
  // ...
};
```
- **Minimum 8 characters**
- **At least 1 uppercase letter**
- **At least 1 lowercase letter**
- **At least 1 number**
- Production: có thể thêm special characters, check against common passwords

**4. Check existing user**:
```javascript
const existingUser = await docClient.send(
  new GetCommand({
    TableName: "CoffeeUsers",
    Key: { email }
  })
);

if (existingUser.Item) {
  return { statusCode: 409, ... }; // HTTP 409 Conflict
}
```
- **GetCommand**: Query by primary key (email)
- Return 409 nếu email đã tồn tại
- Prevents duplicate accounts

**5. Hash password**:
```javascript
const hashedPassword = await bcrypt.hash(password, SALT_ROUNDS);
```
- **SALT_ROUNDS = 10**: Recommended default
- **Time**: ~100ms to hash
- **Output**: String dạng `$2b$10$...` (60 characters)

**6. Save user**:
```javascript
const user = {
  email,
  userId,
  passwordHash: hashedPassword, // Hash, not plain text
  // ...
};
```
- **passwordHash**: Lưu hash, KHÔNG bao giờ lưu plain text password
- **role**: Default = 'customer' (có thể có 'admin' sau này)

**7. Response không bao gồm passwordHash**:
```javascript
body: JSON.stringify({
  user: {
    userId,
    email,
    name
    // passwordHash KHÔNG được return
  }
})
```
- **Security**: Không bao giờ expose password hash về client
- Chỉ return public user info

3. Click **Deploy**

**Bước 5**: Update Handler & Settings

1. **Runtime settings** → **Edit** → **Handler**: `index.handler`
2. **Configuration** → **General configuration** → **Edit**:
   - **Timeout**: 30 seconds
   - **Memory**: 256 MB (tăng từ 128 MB vì bcrypt cần compute power)
3. Click **Save**

**Bước 6**: Test Lambda

1. Tab **Test** → **Create new test event**
2. **Event name**: `testRegister`
3. **Template**: API Gateway AWS Proxy
4. Sửa `body`:

```json
{
  "body": "{\"email\":\"test@example.com\",\"password\":\"Password123\",\"name\":\"Nguyen Van A\",\"phone\":\"0901234567\"}",
  "resource": "/auth/register",
  "path": "/auth/register",
  "httpMethod": "POST",
  "headers": {
    "Content-Type": "application/json"
  }
}
```

5. Click **Save** → Click **Test**

**Kết quả mong đợi**:
- Status: 201
- Response:
```json
{
  "message": "User registered successfully",
  "user": {
    "userId": "user-1707523200000",
    "email": "test@example.com",
    "name": "Nguyen Van A",
    "role": "customer",
    "createdAt": 1707523200000
  }
}
```

6. Verify trong DynamoDB:
   - Tab **Explore table items** của CoffeeUsers
   - Xem user vừa tạo
   - **passwordHash** phải là string dài ~60 characters, bắt đầu bằng `$2b$10$`

**Test edge cases**:

**Test 2: Duplicate email**
- Gửi lại request với cùng email
- **Expected**: 409 Conflict, "User with this email already exists"

**Test 3: Weak password**
```json
{"email":"test2@example.com","password":"weak","name":"Test"}
```
- **Expected**: 400 Bad Request, "Password must be at least 8 characters"

**Test 4: Invalid email**
```json
{"email":"invalid-email","password":"Password123","name":"Test"}
```
- **Expected**: 400 Bad Request, "Invalid email format"

---

## BƯỚC 4.4: TẠO API GATEWAY - POST /AUTH/REGISTER

**Bước 1**: Mở API Gateway Console

1. API Gateway → CoffeeShopAPI

**Bước 2**: Tạo Resource /auth

1. Click root `/`
2. **Actions** → **Create Resource**
3. **Resource Name**: `auth`
4. **Resource Path**: `/auth`
5. **Enable API Gateway CORS**: ☑ Check
6. Click **Create Resource**

**Bước 3**: Tạo Resource /auth/register

1. Click resource `/auth`
2. **Actions** → **Create Resource**
3. **Resource Name**: `register`
4. **Resource Path**: `/register`
5. **Enable API Gateway CORS**: ☑ Check
6. Click **Create Resource**

**Bước 4**: Tạo POST Method

1. Click resource `/auth/register`
2. **Actions** → **Create Method**
3. Dropdown: **POST**
4. Click ✓

5. **Setup**:
   - **Integration type**: Lambda Function
   - **Use Lambda Proxy integration**: ☑ Check
   - **Lambda Function**: `coffee-register-user`
6. Click **Save** → **OK**

**Bước 5**: Enable CORS

1. Click resource `/auth/register`
2. **Actions** → **Enable CORS**
3. **Access-Control-Allow-Methods**: POST, OPTIONS
4. Click **Enable CORS and replace existing CORS headers**
5. Confirm

**Bước 6**: Test trong Console

1. Click method **POST**
2. Click **TEST**
3. **Request Body**:

```json
{
  "email": "john@example.com",
  "password": "SecurePass123",
  "name": "John Doe",
  "phone": "0909123456"
}
```

4. Click **Test**
5. Verify: Status 201, user created

**Bước 7**: Deploy API

1. **Actions** → **Deploy API**
2. **Stage**: prod
3. Click **Deploy**

**Bước 8**: Test với cURL

```bash
curl -X POST https://YOUR-API-ID.execute-api.ap-southeast-1.amazonaws.com/prod/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "jane@example.com",
    "password": "MySecurePass456",
    "name": "Jane Smith",
    "phone": "0908765432"
  }'
```

**Kết quả mong đợi**:
```json
{
  "message": "User registered successfully",
  "user": {
    "userId": "user-1707523200000",
    "email": "jane@example.com",
    "name": "Jane Smith",
    "role": "customer",
    "createdAt": 1707523200000
  }
}
```

---

## 🔗 <a id="frontend-integration-register"></a>TÍCH HỢP FRONTEND - REGISTER FEATURE

### Bước 1: Cập nhật API Config

File: `src/config/api.config.js`

Đảm bảo bạn đã có:
```javascript
const API_CONFIG = {
  BASE_URL: import.meta.env.VITE_API_BASE_URL || 'https://YOUR-API-ID.execute-api.ap-southeast-1.amazonaws.com/prod',
  ENDPOINTS: {
    // ...existing endpoints
    REGISTER: '/auth/register',
  },
  TIMEOUT: 30000,
};

export default API_CONFIG;
```

**Giải thích**:
- `VITE_API_BASE_URL`: Environment variable cho flexibility (dev/prod)
- Có thể tạo file `.env.local`:
  ```
  VITE_API_BASE_URL=https://xyz123.execute-api.ap-southeast-1.amazonaws.com/prod
  ```

### Bước 2: Cập nhật authService

File: `src/services/authService.js`

Tìm hàm `register` và cập nhật:

```javascript
import API_CONFIG from '../config/api.config.js';

const authService = {
  /**
   * Register new user
   * @param {Object} userData - {email, password, name, phone}
   * @returns {Promise<Object>} User data
   */
  async register(userData) {
    try {
      const response = await fetch(`${API_CONFIG.BASE_URL}${API_CONFIG.ENDPOINTS.REGISTER}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(userData),
      });

      const data = await response.json();

      if (!response.ok) {
        // Handle error responses from backend
        throw new Error(data.message || 'Registration failed');
      }

      return data; // {message: "...", user: {...}}
    } catch (error) {
      console.error('Registration error:', error);
      throw error;
    }
  },

  // ...other methods
};

export default authService;
```

**Key points**:
- **Error handling**: Check `response.ok` và throw error với backend message
- **Return data**: Backend trả về `{message, user}`
- **No token yet**: Register chỉ tạo user, chưa login

### Bước 3: Cập nhật Register Component

File: `src/components/auth/Register.jsx`

```javascript
import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import authService from '../../services/authService';
import './Register.css';

const Register = () => {
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    phone: '',
    password: '',
    confirmPassword: ''
  });
  const [errors, setErrors] = useState({});
  const [loading, setLoading] = useState(false);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
    // Clear error when user types
    if (errors[name]) {
      setErrors(prev => ({ ...prev, [name]: '' }));
    }
  };

  const validateForm = () => {
    const newErrors = {};

    // Name validation
    if (!formData.name.trim()) {
      newErrors.name = 'Name is required';
    }

    // Email validation
    if (!formData.email.trim()) {
      newErrors.email = 'Email is required';
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email)) {
      newErrors.email = 'Invalid email format';
    }

    // Password validation (match backend requirements)
    if (!formData.password) {
      newErrors.password = 'Password is required';
    } else if (formData.password.length < 8) {
      newErrors.password = 'Password must be at least 8 characters';
    } else if (!/[A-Z]/.test(formData.password)) {
      newErrors.password = 'Password must contain at least one uppercase letter';
    } else if (!/[a-z]/.test(formData.password)) {
      newErrors.password = 'Password must contain at least one lowercase letter';
    } else if (!/[0-9]/.test(formData.password)) {
      newErrors.password = 'Password must contain at least one number';
    }

    // Confirm password validation
    if (formData.password !== formData.confirmPassword) {
      newErrors.confirmPassword = 'Passwords do not match';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    // Frontend validation
    if (!validateForm()) {
      return;
    }

    setLoading(true);

    try {
      // Call backend API
      const result = await authService.register({
        name: formData.name,
        email: formData.email,
        phone: formData.phone,
        password: formData.password
        // confirmPassword không gửi lên backend
      });

      console.log('Registration successful:', result);

      // Show success message
      alert(`Registration successful! Welcome, ${result.user.name}!`);

      // Redirect to login page
      navigate('/login');

    } catch (error) {
      console.error('Registration failed:', error);
      
      // Display backend error message
      setErrors({
        submit: error.message || 'Registration failed. Please try again.'
      });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="register-container">
      <div className="register-card">
        <h2>Create Account</h2>
        <form onSubmit={handleSubmit} className="register-form">
          <div className="form-group">
            <label htmlFor="name">Full Name *</label>
            <input
              type="text"
              id="name"
              name="name"
              value={formData.name}
              onChange={handleChange}
              placeholder="Enter your full name"
              disabled={loading}
            />
            {errors.name && <span className="error-message">{errors.name}</span>}
          </div>

          <div className="form-group">
            <label htmlFor="email">Email *</label>
            <input
              type="email"
              id="email"
              name="email"
              value={formData.email}
              onChange={handleChange}
              placeholder="Enter your email"
              disabled={loading}
            />
            {errors.email && <span className="error-message">{errors.email}</span>}
          </div>

          <div className="form-group">
            <label htmlFor="phone">Phone Number</label>
            <input
              type="tel"
              id="phone"
              name="phone"
              value={formData.phone}
              onChange={handleChange}
              placeholder="Enter your phone number"
              disabled={loading}
            />
          </div>

          <div className="form-group">
            <label htmlFor="password">Password *</label>
            <input
              type="password"
              id="password"
              name="password"
              value={formData.password}
              onChange={handleChange}
              placeholder="Create a strong password"
              disabled={loading}
            />
            {errors.password && <span className="error-message">{errors.password}</span>}
            <small className="password-hint">
              Must contain: 8+ characters, uppercase, lowercase, and number
            </small>
          </div>

          <div className="form-group">
            <label htmlFor="confirmPassword">Confirm Password *</label>
            <input
              type="password"
              id="confirmPassword"
              name="confirmPassword"
              value={formData.confirmPassword}
              onChange={handleChange}
              placeholder="Re-enter your password"
              disabled={loading}
            />
            {errors.confirmPassword && <span className="error-message">{errors.confirmPassword}</span>}
          </div>

          {errors.submit && (
            <div className="error-banner">
              {errors.submit}
            </div>
          )}

          <button 
            type="submit" 
            className="btn-register"
            disabled={loading}
          >
            {loading ? 'Creating Account...' : 'Create Account'}
          </button>
        </form>

        <div className="login-link">
          Already have an account? <a href="/login">Login here</a>
        </div>
      </div>
    </div>
  );
};

export default Register;
```

**Key features**:
- **Frontend validation**: Match backend requirements (8 chars, uppercase, lowercase, number)
- **Password hint**: Hiển thị requirements cho user
- **Error display**: Show backend errors
- **Loading state**: Disable form khi đang submit
- **Success flow**: Alert + redirect to login page

### Bước 4: Test Integration

1. **Start dev server**: `npm run dev`
2. Navigate: `http://localhost:5173/register`
3. Fill form:
   - Name: Test User
   - Email: testuser@example.com
   - Phone: 0901234567
   - Password: TestPass123
   - Confirm: TestPass123
4. Click "Create Account"
5. **Check**:
   - Alert "Registration successful!"
   - Redirect to /login
   - Check DynamoDB: User được tạo
   - Check Console logs

### Bước 5: Debug Common Issues

**Issue 1: CORS error**
```
Access to fetch has been blocked by CORS policy
```
**Fix**: 
- Verify API Gateway CORS enabled
- Check Lambda returns CORS headers
- Verify OPTIONS method exists

**Issue 2: 500 Internal Server Error**
```
{"message":"Error registering user","error":"..."}
```
**Fix**:
- Check CloudWatch Logs của Lambda
- Verify Lambda Layer attached
- Check DynamoDB table name đúng

**Issue 3: Network error**
```
Failed to fetch
```
**Fix**:
- Check BASE_URL đúng không
- Check API deployed chưa
- Test với cURL trước

**Issue 4: Email already exists**
```
{"message":"User with this email already exists"}
```
**Expected behavior**: Show error, user có thể sửa email

---

## ✅ CHECKPOINT 4: HOÀN THÀNH CHỨC NĂNG ĐĂNG KÝ

### 🎉 Bạn đã hoàn thành:

- ✅ Tạo DynamoDB table: CoffeeUsers
- ✅ Tạo Lambda Layer: bcryptjs + jsonwebtoken
- ✅ Tạo Lambda function: coffee-register-user
- ✅ Password hashing với bcrypt (security!)
- ✅ Email & password validation
- ✅ Tạo API: POST /auth/register
- ✅ Tích hợp frontend Register component
- ✅ Test end-to-end thành công

### 📚 Kiến thức đã học:

- **Password Hashing**: bcrypt, salt, cost factor
- **Lambda Layers**: Share dependencies across functions
- **Security**: NEVER store plain text passwords
- **Validation**: Frontend + Backend validation
- **Error handling**: HTTP status codes (400, 409, 500)
- **Frontend integration**: Form handling, error display

---

## 🧪 LAB 5: ĐĂNG NHẬP (POST /auth/login)

### 📖 Lý thuyết: JWT (JSON Web Tokens)

**Tài liệu tham khảo**: [JWT.io](https://jwt.io/introduction)

**JWT** là standard mở (RFC 7519) để truyền thông tin an toàn giữa các parties dưới dạng JSON object.

**Vấn đề cần giải quyết**: Session management

**Traditional sessions (server-side)**:
```
User login → Server tạo session → Lưu session in memory/database
→ Return session ID cookie → User gửi cookie mỗi request
→ Server lookup session → Verify user
```

**Nhược điểm**:
- ❌ Server phải lưu trữ sessions (memory overhead)
- ❌ Khó scale horizontally (multiple servers)
- ❌ Không RESTful (stateful)

**JWT solution (stateless)**:
```
User login → Server tạo JWT token → Return token to client
→ Client lưu token (localStorage/cookie)
→ Mỗi request: Client gửi token trong Authorization header
→ Server verify token signature → Extract user info
```

**Ưu điểm**:
- ✅ Stateless: Server không cần lưu sessions
- ✅ Scalable: Bất kỳ server nào cũng verify được
- ✅ RESTful: Không dựa vào server state
- ✅ Cross-domain: Token có thể dùng cho multiple services

---

### 📚 Lý thuyết: JWT Structure

**JWT có 3 phần**, ngăn cách bởi dấu `.`:

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiJ1c2VyLTEyMyIsImVtYWlsIjoidGVzdEBleGFtcGxlLmNvbSIsImlhdCI6MTcwNzUyMzIwMCwiZXhwIjoxNzA3NjA5NjAwfQ.4Hb-2JtK3C_yL5hN6bwF8RzQpX9mW7vD1eS4aT6cI0k

[      HEADER       ].[                PAYLOAD                                  ].[         SIGNATURE        ]
```

#### 1️⃣ Header (Red)

```json
{
  "alg": "HS256",
  "typ": "JWT"
}
```

- **alg**: Algorithm dùng để sign (HS256 = HMAC SHA256)
- **typ**: Type của token (JWT)

#### 2️⃣ Payload (Purple)

```json
{
  "userId": "user-123",
  "email": "test@example.com",
  "role": "customer",
  "iat": 1707523200,
  "exp": 1707609600
}
```

- **Claims**: Các thông tin về user
- **Standard claims**:
  - `iat` (issued at): Timestamp token được tạo
  - `exp` (expiration): Timestamp token hết hạn
  - `sub` (subject): User identifier
  - `iss` (issuer): Ai tạo token
- **Custom claims**: userId, email, role, etc.

**⚠️ Lưu ý**: Payload KHÔNG được mã hóa, chỉ được encode Base64. Ai cũng có thể decode và đọc. **KHÔNG bao giờ lưu sensitive data** (password, credit card) trong JWT!

#### 3️⃣ Signature (Cyan)

```javascript
HMACSHA256(
  base64UrlEncode(header) + "." + base64UrlEncode(payload),
  secret
)
```

- **Secret key**: String bí mật chỉ server biết
- **Purpose**: Verify token không bị tamper (thay đổi)

**Verification process**:
1. Client gửi JWT
2. Server tách ra: header, payload, signature
3. Server tính signature mới từ header + payload + secret
4. So sánh signature mới với signature trong token
5. Nếu giống → Token valid, nếu khác → Token invalid/tampered

---

### 📚 Lý thuyết: JWT Best Practices

**1. Expiration time**:
- **Access token**: Short-lived (15 mins - 1 hour)
- **Refresh token**: Long-lived (7 days - 30 days)

**Lý do**: Nếu token bị stolen, attacker chỉ dùng được trong thời gian ngắn.

**2. Secret key**:
- **Dài**: Ít nhất 256 bits (32 characters)
- **Random**: Dùng cryptographically secure random generator
- **Lưu trữ an toàn**: Environment variables, AWS Secrets Manager
- **KHÔNG commit** vào git!

**3. Storage (Frontend)**:

**Option 1: localStorage** (Dễ dùng nhưng vulnerable to XSS)
```javascript
localStorage.setItem('token', jwt);
```
- ✅ Persist across browser sessions
- ❌ Accessible by JavaScript → XSS risk

**Option 2: httpOnly cookie** (Secure hơn)
```javascript
// Server set cookie
res.cookie('token', jwt, { httpOnly: true, secure: true });
```
- ✅ Không accessible by JavaScript → XSS safe
- ✅ Automatically sent with requests
- ❌ CSRF risk (cần CSRF protection)

**Recommended**: localStorage cho learning, httpOnly cookie cho production.

**4. Authorization header**:
```
Authorization: Bearer <token>
```

**Format**: `Bearer ${token}`

**Tài liệu**: 
- [JWT Best Practices](https://datatracker.ietf.org/doc/html/rfc8725)
- [OWASP JWT Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/JSON_Web_Token_for_Java_Cheat_Sheet.html)

---

## BƯỚC 5.1: TẠO LAMBDA FUNCTION - LOGIN

**Lưu ý**: Table CoffeeUsers đã được tạo ở LAB 4, không cần tạo lại.

**Bước 1**: Tạo Function

1. Lambda Console → **Create function**
2. **Function name**: `coffee-login-user`
3. **Runtime**: Node.js 20.x
4. **Execution role**: `CoffeeLambdaExecutionRole`
5. Click **Create function**

**Bước 2**: Attach Lambda Layer

1. Scroll xuống **Layers** → **Add a layer**
2. **Custom layers** → `coffee-node-dependencies` → Version 1
3. Click **Add**

**Verify**: Layer `coffee-node-dependencies` attached

**Bước 3**: Configure ES Modules

Tạo `package.json`:
```json
{
  "type": "module"
}
```

**Bước 4**: Viết code Lambda

File `index.mjs`:

```javascript
// Import AWS SDK v3
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, GetCommand } from "@aws-sdk/lib-dynamodb";

// Import từ Lambda Layer
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';

// Khởi tạo DynamoDB client
const client = new DynamoDBClient({ region: "ap-southeast-1" });
const docClient = DynamoDBDocumentClient.from(client);

// JWT Secret - CRITICAL: Đổi thành secret của bạn!
// Production: Lưu trong AWS Secrets Manager
const JWT_SECRET = process.env.JWT_SECRET || 'your-super-secret-jwt-key-change-this-in-production';
const JWT_EXPIRES_IN = '24h'; // Token expires in 24 hours

/**
 * Lambda handler - User login
 * @param {Object} event - API Gateway event
 * @returns {Object} Response with JWT token
 */
export const handler = async (event) => {
  console.log("Event:", JSON.stringify(event, null, 2));
  
  try {
    // Parse request body
    const body = JSON.parse(event.body || '{}');
    const { email, password } = body;
    
    console.log("Login attempt for email:", email);
    
    // Validation: Required fields
    if (!email || !password) {
      return {
        statusCode: 400,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*"
        },
        body: JSON.stringify({
          message: "Missing required fields: email and password"
        })
      };
    }
    
    // Get user from DynamoDB
    const result = await docClient.send(
      new GetCommand({
        TableName: "CoffeeUsers",
        Key: { email }
      })
    );
    
    const user = result.Item;
    
    // Check if user exists
    if (!user) {
      // NOTE: Không nên reveal "user not found" vs "wrong password"
      // Để tránh user enumeration attack
      return {
        statusCode: 401, // Unauthorized
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*"
        },
        body: JSON.stringify({
          message: "Invalid email or password"
        })
      };
    }
    
    // Verify password
    console.log("Verifying password...");
    const isPasswordValid = await bcrypt.compare(password, user.passwordHash);
    
    if (!isPasswordValid) {
      console.log("Invalid password for user:", email);
      return {
        statusCode: 401,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*"
        },
        body: JSON.stringify({
          message: "Invalid email or password"
        })
      };
    }
    
    console.log("Password valid, generating JWT token...");
    
    // Generate JWT token
    const token = jwt.sign(
      {
        // Payload - thông tin user (KHÔNG bao gồm password!)
        userId: user.userId,
        email: user.email,
        role: user.role,
        name: user.name
      },
      JWT_SECRET,
      {
        // Options
        expiresIn: JWT_EXPIRES_IN,
        issuer: 'coffee-shop-api'
      }
    );
    
    console.log("Login successful for user:", user.userId);
    
    // Return success with token and user info
    return {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS"
      },
      body: JSON.stringify({
        message: "Login successful",
        token, // JWT token
        user: {
          userId: user.userId,
          email: user.email,
          name: user.name,
          role: user.role
          // KHÔNG return passwordHash!
        }
      })
    };
    
  } catch (error) {
    console.error("Error during login:", error);
    
    return {
      statusCode: 500,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      },
      body: JSON.stringify({
        message: "Error during login",
        error: error.message
      })
    };
  }
};
```

**Giải thích code chi tiết**:

**1. Import jwt**:
```javascript
import jwt from 'jsonwebtoken';
```
- JWT library từ Lambda Layer
- Functions: `jwt.sign()`, `jwt.verify()`

**2. JWT Secret**:
```javascript
const JWT_SECRET = process.env.JWT_SECRET || 'your-super-secret-jwt-key...';
```
- **CRITICAL**: Đây là key để sign tokens
- **Production**: PHẢI lưu trong environment variable hoặc AWS Secrets Manager
- **KHÔNG hard-code** secret trong production code!

**3. Get user**:
```javascript
const result = await docClient.send(
  new GetCommand({
    TableName: "CoffeeUsers",
    Key: { email }
  })
);
```
- Query by email (primary key)
- Efficient O(1) lookup

**4. User not found**:
```javascript
if (!user) {
  return { statusCode: 401, message: "Invalid email or password" };
}
```
- Return **generic message** "Invalid email or password"
- **KHÔNG** reveal "User not found" vs "Wrong password"
- **Prevention**: User enumeration attack (attacker không biết email nào tồn tại)

**5. Verify password**:
```javascript
const isPasswordValid = await bcrypt.compare(password, user.passwordHash);
```
- `bcrypt.compare()`: So sánh plain text password với hash
- bcrypt tự động extract salt từ hash và verify
- Returns: boolean (true/false)

**6. Generate JWT**:
```javascript
const token = jwt.sign(
  { userId, email, role, name }, // Payload
  JWT_SECRET,                     // Secret key
  { expiresIn: '24h' }           // Options
);
```
- **Payload**: User data (KHÔNG có password!)
- **Secret**: Private key để sign
- **expiresIn**: Token expiration time
  - `'24h'` = 24 hours
  - `'7d'` = 7 days
  - `1440` = 1440 minutes (24 hours)

**7. Return token**:
```javascript
body: JSON.stringify({
  message: "Login successful",
  token,        // JWT token - client lưu để auth các requests sau
  user: {...}   // User info để hiển thị
})
```
- Client nhận token và lưu (localStorage/cookie)
- Client gửi token trong header cho các API calls sau

**Bước 5**: Configure Environment Variable (Optional)

1. Tab **Configuration** → **Environment variables** → **Edit**
2. Click **Add environment variable**
3. **Key**: `JWT_SECRET`
4. **Value**: `change-this-to-random-secret-key-for-production-use-min-32-chars`

**Generate secure secret**:
```bash
# Linux/Mac
openssl rand -base64 32

# Node.js
node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"

# PowerShell
$bytes = New-Object byte[] 32
[Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($bytes)
[Convert]::ToBase64String($bytes)
```

**Output example**: `kR9mW2pX7vD4hN5bF8tL3cY6sA1qE0uT9zV4jM8nG2o=`

5. Click **Save**

**Bước 6**: Update Handler & Settings

1. **Runtime settings** → **Handler**: `index.handler`
2. **General configuration**:
   - **Timeout**: 30 seconds
   - **Memory**: 256 MB
3. Click **Save**

**Bước 7**: Test Lambda

**Test 1: Successful login**

1. Tab **Test** → **Create new test event**
2. **Event name**: `testLogin`
3. **Body**:

```json
{
  "body": "{\"email\":\"test@example.com\",\"password\":\"Password123\"}",
  "resource": "/auth/login",
  "path": "/auth/login",
  "httpMethod": "POST",
  "headers": {
    "Content-Type": "application/json"
  }
}
```

**⚠️ Lưu ý**: Dùng email và password của user đã tạo ở LAB 4!

4. Click **Test**

**Kết quả mong đợi**:
- Status: 200
- Response:
```json
{
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "userId": "user-1707523200000",
    "email": "test@example.com",
    "name": "Nguyen Van A",
    "role": "customer"
  }
}
```

5. **Copy token** và verify tại [jwt.io](https://jwt.io):
   - Paste token vào Debugger
   - Verify payload chứa userId, email, role
   - Check expiration time

**Test 2: Wrong password**

Body:
```json
{"email":"test@example.com","password":"WrongPassword"}
```

**Expected**: 401 Unauthorized, "Invalid email or password"

**Test 3: User not found**

Body:
```json
{"email":"notexist@example.com","password":"Password123"}
```

**Expected**: 401 Unauthorized, "Invalid email or password"

**Test 4: Missing fields**

Body:
```json
{"email":"test@example.com"}
```

**Expected**: 400 Bad Request, "Missing required fields"

---

## BƯỚC 5.2: TẠO API GATEWAY - POST /AUTH/LOGIN

**Bước 1**: Mở API Gateway Console

1. API Gateway → CoffeeShopAPI
2. Resource `/auth` đã tồn tại từ LAB 4

**Bước 2**: Tạo Resource /auth/login

1. Click resource `/auth`
2. **Actions** → **Create Resource**
3. **Resource Name**: `login`
4. **Resource Path**: `/login`
5. **Enable API Gateway CORS**: ☑ Check
6. Click **Create Resource**

**Bước 3**: Tạo POST Method

1. Click resource `/auth/login`
2. **Actions** → **Create Method**
3. Dropdown: **POST**
4. Click ✓

5. **Setup**:
   - **Integration type**: Lambda Function
   - **Use Lambda Proxy integration**: ☑ Check
   - **Lambda Function**: `coffee-login-user`
6. Click **Save** → **OK**

**Bước 4**: Enable CORS

1. Click resource `/auth/login`
2. **Actions** → **Enable CORS**
3. **Methods**: POST, OPTIONS
4. Click **Enable CORS and replace existing CORS headers**
5. Confirm

**Bước 5**: Test trong Console

1. Click method **POST**
2. Click **TEST**
3. **Request Body**:

```json
{
  "email": "test@example.com",
  "password": "Password123"
}
```

4. Click **Test**
5. Verify: Status 200, token returned

**Bước 6**: Deploy API

1. **Actions** → **Deploy API**
2. **Stage**: prod
3. Click **Deploy**

**Bước 7**: Test với cURL

```bash
curl -X POST https://YOUR-API-ID.execute-api.ap-southeast-1.amazonaws.com/prod/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Password123"
  }'
```

**Kết quả mong đợi**:
```json
{
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiJ1c2VyLTE3MDc1MjMyMDAwMDAiLCJlbWFpbCI6InRlc3RAZXhhbXBsZS5jb20iLCJyb2xlIjoiY3VzdG9tZXIiLCJuYW1lIjoiTmd1eWVuIFZhbiBBIiwiaWF0IjoxNzA3NTIzMjAwLCJleHAiOjE3MDc2MDk2MDAsImlzcyI6ImNvZmZlZS1zaG9wLWFwaSJ9.example-signature",
  "user": {
    "userId": "user-1707523200000",
    "email": "test@example.com",
    "name": "Nguyen Van A",
    "role": "customer"
  }
}
```

---

## 🔗 <a id="frontend-integration-login"></a>TÍCH HỢP FRONTEND - LOGIN FEATURE

### Bước 1: Cập nhật API Config

File: `src/config/api.config.js`

```javascript
const API_CONFIG = {
  BASE_URL: import.meta.env.VITE_API_BASE_URL || 'https://YOUR-API-ID.execute-api.ap-southeast-1.amazonaws.com/prod',
  ENDPOINTS: {
    // ...existing
    REGISTER: '/auth/register',
    LOGIN: '/auth/login',
  },
  TIMEOUT: 30000,
};

export default API_CONFIG;
```

### Bước 2: Cập nhật authService

File: `src/services/authService.js`

```javascript
import API_CONFIG from '../config/api.config.js';

const authService = {
  // ...register method from LAB 4

  /**
   * Login user
   * @param {Object} credentials - {email, password}
   * @returns {Promise<Object>} {token, user}
   */
  async login(credentials) {
    try {
      const response = await fetch(`${API_CONFIG.BASE_URL}${API_CONFIG.ENDPOINTS.LOGIN}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(credentials),
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.message || 'Login failed');
      }

      // Store token in localStorage
      if (data.token) {
        localStorage.setItem('token', data.token);
        localStorage.setItem('user', JSON.stringify(data.user));
      }

      return data; // {message, token, user}
    } catch (error) {
      console.error('Login error:', error);
      throw error;
    }
  },

  /**
   * Logout user
   */
  logout() {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
  },

  /**
   * Get current logged in user
   * @returns {Object|null} User object or null
   */
  getCurrentUser() {
    const userStr = localStorage.getItem('user');
    return userStr ? JSON.parse(userStr) : null;
  },

  /**
   * Get auth token
   * @returns {string|null} JWT token
   */
  getToken() {
    return localStorage.getItem('token');
  },

  /**
   * Check if user is authenticated
   * @returns {boolean}
   */
  isAuthenticated() {
    return !!this.getToken();
  }
};

export default authService;
```

**Key features**:
- **Login**: Call API, store token + user data
- **Logout**: Clear localStorage
- **getCurrentUser**: Get user info
- **getToken**: Get JWT token for API calls
- **isAuthenticated**: Check login status

### Bước 3: Cập nhật AuthContext

File: `src/context/AuthContext.jsx`

```javascript
import { createContext, useContext, useState, useEffect } from 'react';
import authService from '../services/authService';

const AuthContext = createContext(null);

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Initialize: Load user from localStorage on mount
  useEffect(() => {
    const currentUser = authService.getCurrentUser();
    if (currentUser) {
      setUser(currentUser);
    }
    setLoading(false);
  }, []);

  /**
   * Login function
   */
  const login = async (email, password) => {
    try {
      setError(null);
      setLoading(true);

      const result = await authService.login({ email, password });
      
      setUser(result.user);
      return result;
    } catch (err) {
      setError(err.message);
      throw err;
    } finally {
      setLoading(false);
    }
  };

  /**
   * Register function
   */
  const register = async (userData) => {
    try {
      setError(null);
      setLoading(true);

      const result = await authService.register(userData);
      
      // After register, do NOT auto-login
      // User should login manually
      return result;
    } catch (err) {
      setError(err.message);
      throw err;
    } finally {
      setLoading(false);
    }
  };

  /**
   * Logout function
   */
  const logout = () => {
    authService.logout();
    setUser(null);
  };

  /**
   * Check if user is logged in
   */
  const isLoggedIn = () => {
    return !!user;
  };

  /**
   * Check if user is admin
   */
  const isAdmin = () => {
    return user?.role === 'admin';
  };

  const value = {
    user,
    loading,
    error,
    login,
    register,
    logout,
    isLoggedIn,
    isAdmin
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};

// Custom hook
export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
};
```

**Key features**:
- **State management**: user, loading, error
- **Persistence**: Load user từ localStorage on mount
- **Functions**: login, register, logout, isLoggedIn, isAdmin

### Bước 4: Cập nhật Login Component

File: `src/components/auth/Login.jsx`

```javascript
import { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import './Login.css';

const Login = () => {
  const navigate = useNavigate();
  const { login } = useAuth();
  
  const [formData, setFormData] = useState({
    email: '',
    password: ''
  });
  const [errors, setErrors] = useState({});
  const [loading, setLoading] = useState(false);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
    // Clear error when user types
    if (errors[name]) {
      setErrors(prev => ({ ...prev, [name]: '' }));
    }
  };

  const validateForm = () => {
    const newErrors = {};

    if (!formData.email.trim()) {
      newErrors.email = 'Email is required';
    }

    if (!formData.password) {
      newErrors.password = 'Password is required';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    if (!validateForm()) {
      return;
    }

    setLoading(true);

    try {
      // Call AuthContext login
      const result = await login(formData.email, formData.password);

      console.log('Login successful:', result);

      // Show success message
      alert(`Welcome back, ${result.user.name}!`);

      // Redirect to home page
      navigate('/');

    } catch (error) {
      console.error('Login failed:', error);
      
      setErrors({
        submit: error.message || 'Login failed. Please check your credentials.'
      });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-container">
      <div className="login-card">
        <h2>Login to Your Account</h2>
        
        <form onSubmit={handleSubmit} className="login-form">
          <div className="form-group">
            <label htmlFor="email">Email</label>
            <input
              type="email"
              id="email"
              name="email"
              value={formData.email}
              onChange={handleChange}
              placeholder="Enter your email"
              disabled={loading}
            />
            {errors.email && <span className="error-message">{errors.email}</span>}
          </div>

          <div className="form-group">
            <label htmlFor="password">Password</label>
            <input
              type="password"
              id="password"
              name="password"
              value={formData.password}
              onChange={handleChange}
              placeholder="Enter your password"
              disabled={loading}
            />
            {errors.password && <span className="error-message">{errors.password}</span>}
          </div>

          {errors.submit && (
            <div className="error-banner">
              {errors.submit}
            </div>
          )}

          <button 
            type="submit" 
            className="btn-login"
            disabled={loading}
          >
            {loading ? 'Logging in...' : 'Login'}
          </button>
        </form>

        <div className="register-link">
          Don't have an account? <Link to="/register">Register here</Link>
        </div>
      </div>
    </div>
  );
};

export default Login;
```

**Key features**:
- **useAuth hook**: Access AuthContext
- **Success flow**: Alert + redirect to home
- **Error handling**: Display backend errors
- **Link to register**: Easy navigation

### Bước 5: Protected Routes

File: `src/components/common/ProtectedRoute.jsx` (Tạo mới nếu chưa có)

```javascript
import { Navigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';

/**
 * Protected Route Component
 * Redirects to /login if user not authenticated
 */
const ProtectedRoute = ({ children }) => {
  const { isLoggedIn, loading } = useAuth();

  if (loading) {
    return <div>Loading...</div>;
  }

  if (!isLoggedIn()) {
    // Redirect to login page
    return <Navigate to="/login" replace />;
  }

  return children;
};

export default ProtectedRoute;
```

**Usage in Routing.jsx**:

```javascript
import { Routes, Route } from 'react-router-dom';
import ProtectedRoute from './components/common/ProtectedRoute';
// ...other imports

const Routing = () => {
  return (
    <Routes>
      <Route path="/" element={<HomePage />} />
      <Route path="/products" element={<ProductsPage />} />
      <Route path="/login" element={<Login />} />
      <Route path="/register" element={<Register />} />
      
      {/* Protected routes */}
      <Route 
        path="/profile" 
        element={
          <ProtectedRoute>
            <ProfilePage />
          </ProtectedRoute>
        } 
      />
      <Route 
        path="/orders" 
        element={
          <ProtectedRoute>
            <OrderHistoryPage />
          </ProtectedRoute>
        } 
      />
      <Route 
        path="/cart" 
        element={
          <ProtectedRoute>
            <CartPage />
          </ProtectedRoute>
        } 
      />
    </Routes>
  );
};

export default Routing;
```

### Bước 6: Authenticated API Calls

**Update orderService to send JWT token**:

File: `src/services/orderService.js`

```javascript
import API_CONFIG from '../config/api.config.js';
import authService from './authService.js';

const orderService = {
  /**
   * Create new order (requires authentication)
   */
  async createOrder(orderData) {
    try {
      // Get JWT token
      const token = authService.getToken();

      const response = await fetch(`${API_CONFIG.BASE_URL}${API_CONFIG.ENDPOINTS.ORDERS}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          // Send JWT token in Authorization header
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify(orderData),
      });

      const data = await response.json();

      if (!response.ok) {
        // Handle 401 Unauthorized
        if (response.status === 401) {
          // Token expired or invalid
          authService.logout();
          window.location.href = '/login';
          throw new Error('Session expired. Please login again.');
        }
        throw new Error(data.message || 'Failed to create order');
      }

      return data;
    } catch (error) {
      console.error('Create order error:', error);
      throw error;
    }
  },

  /**
   * Get user's orders (requires authentication)
   */
  async getUserOrders() {
    try {
      const token = authService.getToken();
      const user = authService.getCurrentUser();

      const response = await fetch(
        `${API_CONFIG.BASE_URL}${API_CONFIG.ENDPOINTS.ORDERS}?userId=${user.userId}`,
        {
          headers: {
            'Authorization': `Bearer ${token}`
          }
        }
      );

      const data = await response.json();

      if (!response.ok) {
        if (response.status === 401) {
          authService.logout();
          window.location.href = '/login';
          throw new Error('Session expired. Please login again.');
        }
        throw new Error(data.message || 'Failed to fetch orders');
      }

      return data.orders || [];
    } catch (error) {
      console.error('Get orders error:', error);
      throw error;
    }
  }
};

export default orderService;
```

**Key features**:
- **Authorization header**: `Bearer ${token}`
- **401 handling**: Auto logout + redirect to login
- **User context**: Use userId from current user

### Bước 7: Update Header/Navbar

File: `src/components/common/Header.jsx`

```javascript
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import './Header.css';

const Header = () => {
  const navigate = useNavigate();
  const { user, isLoggedIn, logout } = useAuth();

  const handleLogout = () => {
    logout();
    alert('Logged out successfully!');
    navigate('/login');
  };

  return (
    <header className="header">
      <div className="header-container">
        <Link to="/" className="logo">
          ☕ Coffee Shop
        </Link>

        <nav className="nav-menu">
          <Link to="/">Home</Link>
          <Link to="/products">Products</Link>
          
          {isLoggedIn() ? (
            <>
              <Link to="/orders">My Orders</Link>
              <Link to="/cart">Cart</Link>
              <Link to="/profile">Profile</Link>
              <button onClick={handleLogout} className="btn-logout">
                Logout
              </button>
              <span className="user-name">👤 {user?.name}</span>
            </>
          ) : (
            <>
              <Link to="/login" className="btn-login">Login</Link>
              <Link to="/register" className="btn-register">Register</Link>
            </>
          )}
        </nav>
      </div>
    </header>
  );
};

export default Header;
```

**Key features**:
- **Conditional rendering**: Show different menus based on login status
- **User name display**: Show logged-in user's name
- **Logout button**: Clear session and redirect

### Bước 8: Test Full Flow

**Flow 1: Register → Login → Place Order**

1. **Register**: 
   - Go to `/register`
   - Fill form: name, email, password
   - Click "Create Account"
   - Check: Redirect to `/login`

2. **Login**:
   - Enter email + password
   - Click "Login"
   - Check: 
     - Alert "Welcome back!"
     - Redirect to `/`
     - Header shows user name + logout button
     - localStorage has `token` and `user`

3. **Place Order**:
   - Add products to cart
   - Go to `/cart`
   - Fill order form
   - Click "Place Order"
   - Check:
     - Request includes `Authorization: Bearer <token>`
     - Order created successfully
     - Check DynamoDB: Order với userId

4. **View Orders**:
   - Go to `/orders`
   - Check: Your orders displayed
   - Check: Request includes token

5. **Logout**:
   - Click "Logout"
   - Check:
     - localStorage cleared
     - Redirect to `/login`
     - Protected routes redirect to login

**Flow 2: Access Protected Route without Login**

1. Clear localStorage (or open incognito)
2. Try to access `/orders`
3. Check: Auto redirect to `/login`

**Flow 3: Token Expiration (Optional)**

1. Login successfully
2. Wait 24 hours (or manually expire token)
3. Try to create order
4. Check: 
   - API returns 401
   - Auto logout
   - Redirect to login

### Bước 9: Debug Common Issues

**Issue 1: Token not sent**
```
Backend returns 401: "No token provided"
```
**Fix**: 
- Check `Authorization` header format: `Bearer <token>`
- Verify token exists in localStorage
- Check authService.getToken() returns correct value

**Issue 2: Token expired**
```
Backend returns 401: "Token expired"
```
**Fix**:
- Login again to get new token
- Increase JWT_EXPIRES_IN if needed
- Implement refresh token mechanism (advanced)

**Issue 3: User not persisted after refresh**
```
Page refresh → User logged out
```
**Fix**:
- Check AuthContext useEffect loads from localStorage
- Verify localStorage.getItem('user') returns data
- Check browser doesn't clear localStorage

**Issue 4: CORS with Authorization header**
```
Preflight request failed
```
**Fix**:
- API Gateway CORS: Add "Authorization" to allowed headers
- Lambda CORS response: Include "Authorization" in Access-Control-Allow-Headers

---

## ✅ CHECKPOINT 5: HOÀN THÀNH CHỨC NĂNG ĐĂNG NHẬP

### 🎉 Bạn đã hoàn thành:

- ✅ Tạo Lambda function: coffee-login-user
- ✅ JWT token generation với jsonwebtoken
- ✅ Password verification với bcrypt.compare
- ✅ Tạo API: POST /auth/login
- ✅ Tích hợp frontend Login component
- ✅ AuthContext state management
- ✅ Protected routes
- ✅ Authenticated API calls với JWT
- ✅ Logout functionality
- ✅ Test full authentication flow

### 📚 Kiến thức đã học:

- **JWT**: Structure (header, payload, signature), signing, verification
- **Token-based authentication**: Stateless, scalable
- **Authorization header**: Bearer token format
- **Protected routes**: Redirect if not authenticated
- **Token storage**: localStorage pros/cons
- **Session management**: Login, logout, persistence
- **Security**: Don't expose passwordHash, generic error messages
- **User experience**: Auto logout on token expiration

---

## 🎊 TỔNG KẾT HOÀN CHỈNH: COFFEE SHOP E-COMMERCE BACKEND

### 🎉 Chúc mừng! Bạn đã hoàn thành tất cả 5 LAB!

Backend của Coffee Shop đã có đầy đủ chức năng production-ready với AWS Serverless Architecture.

---

## 📊 FINAL ARCHITECTURE OVERVIEW

### 🏗️ Architecture Diagram

```
┌─────────────┐
│   Frontend  │
│ (React SPA) │
│ localhost:  │
│    5173     │
└──────┬──────┘
       │ HTTPS
       ↓
┌─────────────────────────────────────────────────────────────────┐
│                      API Gateway (REST API)                      │
│                         CoffeeShopAPI                            │
│                   Regional - ap-southeast-1                      │
├─────────────────────────────────────────────────────────────────┤
│  GET    /products           → coffee-get-products               │
│  POST   /orders             → coffee-create-order               │
│  GET    /orders?userId=xxx  → coffee-get-orders                 │
│  POST   /auth/register      → coffee-register-user              │
│  POST   /auth/login         → coffee-login-user                 │
└──────┬──────────────┬───────────────┬──────────────┬────────────┘
       │              │               │              │
       ↓              ↓               ↓              ↓
┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│   Lambda    │ │   Lambda    │ │   Lambda    │ │   Lambda    │
│   Layer     │ │   Layer     │ │   Layer     │ │   Layer     │
│  (Shared)   │ │  (Shared)   │ │  (Shared)   │ │  (Shared)   │
├─────────────┤ ├─────────────┤ ├─────────────┤ ├─────────────┤
│   Lambda    │ │   Lambda    │ │   Lambda    │ │   Lambda    │
│ get-products│ │create-order │ │ get-orders  │ │register-user│
│             │ │             │ │             │ │             │
│ Node 20.x   │ │ Node 20.x   │ │ Node 20.x   │ │ Node 20.x   │
│ ES Module   │ │ ES Module   │ │ ES Module   │ │ ES Module   │
│ 128MB       │ │ 128MB       │ │ 128MB       │ │ 256MB       │
└──────┬──────┘ └──────┬──────┘ └──────┬──────┘ └──────┬──────┘
       │               │                │               │
       ↓               ↓                ↓               ↓
┌─────────────────────────────────────────────────────────────────┐
│                         DynamoDB Tables                          │
├───────────────┬──────────────────────┬───────────────────────────┤
│CoffeeProducts │   CoffeeOrders       │    CoffeeUsers            │
│               │                      │                           │
│PK: productId  │ PK: orderId          │ PK: email                 │
│               │ GSI: UserIdIndex     │                           │
│               │  - userId (PK)       │                           │
│               │  - createdAt (SK)    │                           │
└───────────────┴──────────────────────┴───────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                          IAM Roles                               │
├─────────────────────────────────────────────────────────────────┤
│  CoffeeLambdaExecutionRole                                       │
│    - CoffeeLambdaPolicy (DynamoDB + CloudWatch permissions)     │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                       Lambda Layer                               │
├─────────────────────────────────────────────────────────────────┤
│  coffee-node-dependencies                                        │
│    - bcryptjs (password hashing)                                │
│    - jsonwebtoken (JWT generation/verification)                 │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      CloudWatch Logs                             │
│               (All Lambda execution logs)                        │
└─────────────────────────────────────────────────────────────────┘
```

---

### 📋 RESOURCES INVENTORY

#### DynamoDB Tables (3)

| Table Name | Partition Key | Sort Key | GSI | Items | Use Case |
|------------|---------------|----------|-----|-------|----------|
| **CoffeeProducts** | productId (S) | - | - | ~4 | Store products catalog |
| **CoffeeOrders** | orderId (S) | - | UserIdIndex (userId, createdAt) | Variable | Store customer orders |
| **CoffeeUsers** | email (S) | - | - | Variable | Store user accounts |

#### Lambda Functions (5)

| Function Name | Runtime | Memory | Timeout | Trigger | Purpose |
|---------------|---------|--------|---------|---------|---------|
| **coffee-get-products** | Node 20.x | 128 MB | 30s | GET /products | Fetch all products |
| **coffee-create-order** | Node 20.x | 128 MB | 30s | POST /orders | Create new order |
| **coffee-get-orders** | Node 20.x | 128 MB | 30s | GET /orders | Fetch user's orders |
| **coffee-register-user** | Node 20.x | 256 MB | 30s | POST /auth/register | Register new user |
| **coffee-login-user** | Node 20.x | 256 MB | 30s | POST /auth/login | Login + JWT generation |

#### Lambda Layer (1)

- **coffee-node-dependencies** (Version 1)
  - bcryptjs: ^2.4.3
  - jsonwebtoken: ^9.0.2

#### IAM (2)

- **CoffeeLambdaPolicy**: Custom policy (DynamoDB + CloudWatch permissions)
- **CoffeeLambdaExecutionRole**: Execution role used by all Lambdas

#### API Gateway (1)

- **CoffeeShopAPI** (REST API, Regional)
  - **Stage**: prod
  - **URL**: `https://{api-id}.execute-api.ap-southeast-1.amazonaws.com/prod`
  - **Resources**: 
    - `/products` (GET)
    - `/orders` (POST, GET)
    - `/auth/register` (POST)
    - `/auth/login` (POST)

---

## 🔗 <a id="frontend-integration-complete"></a>HƯỚNG DẪN TÍCH HỢP FRONTEND HOÀN CHỈNH

### Mục lục Integration

1. [LAB 1: Get Products - Frontend Integration](#frontend-integration-products)
2. [LAB 2: Create Order - Frontend Integration](#frontend-integration-create-order)
3. [LAB 3: Get Orders - Frontend Integration](#frontend-integration-get-orders)
4. [LAB 4: Register - Frontend Integration](#frontend-integration-register)
5. [LAB 5: Login - Frontend Integration](#frontend-integration-login)

---

### <a id="frontend-integration-products"></a>📦 LAB 1: Get Products Integration

**Liên kết**: [Xem chi tiết trong LAB 1](#frontend-integration-products)

**API Endpoint**: `GET /products`

**Frontend Files cần cập nhật**:

1. **`src/config/api.config.js`**
```javascript
const API_CONFIG = {
  BASE_URL: import.meta.env.VITE_API_BASE_URL || 'https://YOUR-API-ID.execute-api.ap-southeast-1.amazonaws.com/prod',
  ENDPOINTS: {
    PRODUCTS: '/products',
    // ...
  }
};
```

2. **`src/services/productService.js`**
```javascript
import API_CONFIG from '../config/api.config.js';

const productService = {
  async getAllProducts() {
    const response = await fetch(`${API_CONFIG.BASE_URL}${API_CONFIG.ENDPOINTS.PRODUCTS}`);
    const data = await response.json();
    return data.products || [];
  }
};

export default productService;
```

3. **`src/hooks/useProducts.js`**
```javascript
import { useState, useEffect } from 'react';
import productService from '../services/productService';

export const useProducts = () => {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchProducts = async () => {
      try {
        setLoading(true);
        const data = await productService.getAllProducts();
        setProducts(data);
      } catch (err) {
        setError(err.message);
        console.error('Error fetching products:', err);
      } finally {
        setLoading(false);
      }
    };

    fetchProducts();
  }, []);

  return { products, loading, error };
};
```

4. **`src/pages/ProductsPage.jsx`** hoặc **`HomePage.jsx`**
```javascript
import { useProducts } from '../hooks/useProducts';
import ProductList from '../components/product/ProductList';
import LoadingSpinner from '../components/common/LoadingSpinner';

const ProductsPage = () => {
  const { products, loading, error } = useProducts();

  if (loading) return <LoadingSpinner />;
  if (error) return <div>Error: {error}</div>;

  return (
    <div className="products-page">
      <h1>Our Coffee Products</h1>
      <ProductList products={products} />
    </div>
  );
};

export default ProductsPage;
```

**Test**: 
- Navigate to `/products`
- Products should load from AWS backend
- Check Network tab: See request to API Gateway URL

---

### <a id="frontend-integration-create-order"></a>🛒 LAB 2: Create Order Integration

**Liên kết**: [Xem chi tiết trong LAB 2](#frontend-integration-create-order)

**API Endpoint**: `POST /orders`

**Frontend Files cần cập nhật**:

1. **`src/config/api.config.js`**
```javascript
const API_CONFIG = {
  ENDPOINTS: {
    // ...
    ORDERS: '/orders',
  }
};
```

2. **`src/services/orderService.js`**
```javascript
import API_CONFIG from '../config/api.config.js';
import authService from './authService.js';

const orderService = {
  async createOrder(orderData) {
    const token = authService.getToken();
    
    const response = await fetch(`${API_CONFIG.BASE_URL}${API_CONFIG.ENDPOINTS.ORDERS}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}` // Include JWT if user logged in
      },
      body: JSON.stringify(orderData)
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.message || 'Failed to create order');
    }

    return data;
  }
};

export default orderService;
```

3. **`src/pages/CartPage.jsx`**
```javascript
import { useState } from 'react';
import { useCart } from '../context/CartContext';
import { useAuth } from '../context/AuthContext';
import orderService from '../services/orderService';
import { Order } from '../models/Order';

const CartPage = () => {
  const { items, getTotalPrice, clearCart } = useCart();
  const { user } = useAuth();
  const [formData, setFormData] = useState({
    customerName: user?.name || '',
    email: user?.email || '',
    phone: '',
    address: ''
  });

  const handleSubmit = async (e) => {
    e.preventDefault();

    try {
      // Create order object
      const orderData = {
        userId: user?.userId,
        customerName: formData.customerName,
        email: formData.email,
        phone: formData.phone,
        address: formData.address,
        items: items.map(item => ({
          productId: item.productId,
          nameProduct: item.nameProduct,
          size: item.size,
          price: item.price,
          quantity: item.quantity
        })),
        totalAmount: getTotalPrice()
      };

      // Call API
      const result = await orderService.createOrder(orderData);
      
      console.log('Order created:', result);
      alert(`Order placed successfully! Order ID: ${result.order.orderId}`);
      
      // Clear cart
      clearCart();
      
      // Redirect to orders page
      navigate('/orders');
    } catch (error) {
      console.error('Order creation failed:', error);
      alert('Failed to place order: ' + error.message);
    }
  };

  return (
    <div className="cart-page">
      <h1>Checkout</h1>
      <form onSubmit={handleSubmit}>
        {/* Form fields */}
        <button type="submit">Place Order</button>
      </form>
    </div>
  );
};

export default CartPage;
```

**Test**:
- Add products to cart
- Go to `/cart`
- Fill checkout form
- Click "Place Order"
- Check DynamoDB: Order created with correct data
- Check: Cart cleared, redirected to `/orders`

---

### <a id="frontend-integration-get-orders"></a>📋 LAB 3: Get Orders Integration

**Liên kết**: [Xem chi tiết trong LAB 3](#frontend-integration-get-orders)

**API Endpoint**: `GET /orders?userId={userId}`

**Frontend Files cần cập nhật**:

1. **`src/services/orderService.js`**
```javascript
const orderService = {
  // ...createOrder from LAB 2

  async getUserOrders() {
    const token = authService.getToken();
    const user = authService.getCurrentUser();

    if (!user) {
      throw new Error('User not logged in');
    }

    const response = await fetch(
      `${API_CONFIG.BASE_URL}${API_CONFIG.ENDPOINTS.ORDERS}?userId=${user.userId}`,
      {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      }
    );

    const data = await response.json();

    if (!response.ok) {
      if (response.status === 401) {
        authService.logout();
        window.location.href = '/login';
      }
      throw new Error(data.message || 'Failed to fetch orders');
    }

    return data.orders || [];
  }
};
```

2. **`src/hooks/useOrders.js`**
```javascript
import { useState, useEffect } from 'react';
import orderService from '../services/orderService';
import { useAuth } from '../context/AuthContext';

export const useOrders = () => {
  const { user, isLoggedIn } = useAuth();
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchOrders = async () => {
      if (!isLoggedIn()) {
        setLoading(false);
        return;
      }

      try {
        setLoading(true);
        const data = await orderService.getUserOrders();
        setOrders(data);
      } catch (err) {
        setError(err.message);
        console.error('Error fetching orders:', err);
      } finally {
        setLoading(false);
      }
    };

    fetchOrders();
  }, [user, isLoggedIn]);

  return { orders, loading, error };
};
```

3. **`src/pages/OrderHistoryPage.jsx`**
```javascript
import { useOrders } from '../hooks/useOrders';
import LoadingSpinner from '../components/common/LoadingSpinner';

const OrderHistoryPage = () => {
  const { orders, loading, error } = useOrders();

  if (loading) return <LoadingSpinner />;
  if (error) return <div>Error: {error}</div>;

  return (
    <div className="order-history-page">
      <h1>My Orders</h1>
      {orders.length === 0 ? (
        <p>No orders yet. <a href="/products">Start shopping!</a></p>
      ) : (
        <div className="orders-list">
          {orders.map(order => (
            <div key={order.orderId} className="order-card">
              <h3>Order #{order.orderId}</h3>
              <p>Date: {new Date(order.createdAt).toLocaleDateString()}</p>
              <p>Total: {order.totalAmount}</p>
              <p>Status: {order.status}</p>
              <div className="order-items">
                {order.items.map((item, idx) => (
                  <div key={idx}>
                    {item.quantity}x {item.nameProduct} ({item.size})
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default OrderHistoryPage;
```

**Test**:
- Login as user
- Go to `/orders`
- Check: Orders displayed (sorted by newest first)
- Check: Only your orders (filtered by userId)

---

### <a id="frontend-integration-register"></a>👤 LAB 4: Register Integration

**Liên kết**: [Xem chi tiết trong LAB 4](#frontend-integration-register)

**API Endpoint**: `POST /auth/register`

*Xem hướng dẫn chi tiết đầy đủ trong LAB 4 phần "TÍCH HỢP FRONTEND - REGISTER FEATURE"*

**Key Points**:
- Frontend validation phải match backend requirements
- Password: Min 8 chars, uppercase, lowercase, number
- After register: Redirect to `/login` (NOT auto-login)
- Error handling: Display backend error messages

---

### <a id="frontend-integration-login"></a>🔐 LAB 5: Login Integration

**Liên kết**: [Xem chi tiết trong LAB 5](#frontend-integration-login)

**API Endpoint**: `POST /auth/login`

*Xem hướng dẫn chi tiết đầy đủ trong LAB 5 phần "TÍCH HỢP FRONTEND - LOGIN FEATURE"*

**Key Points**:
- Store JWT token in localStorage
- Store user object in localStorage
- AuthContext manages authentication state
- Protected routes redirect to `/login` if not authenticated
- All authenticated API calls include `Authorization: Bearer {token}` header
- Auto logout on 401 Unauthorized (token expired)

---

## 📝 CHECKLIST: FRONTEND INTEGRATION STEPS

### 1️⃣ Environment Setup

- [ ] Create `.env.local` file:
  ```
  VITE_API_BASE_URL=https://YOUR-API-ID.execute-api.ap-southeast-1.amazonaws.com/prod
  ```
- [ ] Update `src/config/api.config.js` với API Gateway URL
- [ ] Test API endpoints với cURL hoặc Postman trước khi integrate

### 2️⃣ Services Layer

- [ ] `src/services/productService.js` - Get products
- [ ] `src/services/orderService.js` - Create & get orders
- [ ] `src/services/authService.js` - Register, login, logout
- [ ] Add error handling trong tất cả services
- [ ] Add JWT token trong authenticated requests

### 3️⃣ Context & State Management

- [ ] `src/context/AuthContext.jsx` - Authentication state
- [ ] `src/context/CartContext.jsx` - Shopping cart state
- [ ] Load user từ localStorage on app mount
- [ ] Persist cart trong localStorage

### 4️⃣ Custom Hooks

- [ ] `src/hooks/useProducts.js` - Fetch products
- [ ] `src/hooks/useOrders.js` - Fetch user orders
- [ ] Handle loading & error states

### 5️⃣ Components

- [ ] `src/components/auth/Register.jsx` - Registration form
- [ ] `src/components/auth/Login.jsx` - Login form
- [ ] `src/components/common/Header.jsx` - Show login/logout, user name
- [ ] `src/components/common/ProtectedRoute.jsx` - Route protection
- [ ] `src/components/product/ProductList.jsx` - Display products
- [ ] Form validation matching backend requirements

### 6️⃣ Pages

- [ ] `src/pages/HomePage.jsx` - Use useProducts hook
- [ ] `src/pages/ProductsPage.jsx` - Display all products
- [ ] `src/pages/CartPage.jsx` - Checkout form, create order
- [ ] `src/pages/OrderHistoryPage.jsx` - Display user orders
- [ ] `src/pages/ProfilePage.jsx` - User profile

### 7️⃣ Routing

- [ ] `src/Routing.jsx` - Setup all routes
- [ ] Wrap protected routes với ProtectedRoute component
- [ ] Public routes: `/`, `/products`, `/login`, `/register`
- [ ] Protected routes: `/cart`, `/orders`, `/profile`

### 8️⃣ Testing

- [ ] Test register flow: Form → API → Redirect to login
- [ ] Test login flow: Form → API → Store token → Redirect to home
- [ ] Test logout: Clear localStorage → Redirect to login
- [ ] Test protected routes: Access without login → Redirect
- [ ] Test create order: Cart → Checkout → API → Success
- [ ] Test view orders: Orders page → Fetch from API → Display
- [ ] Test token expiration: Wait 24h → Auto logout
- [ ] Test error handling: Network errors, 400/401/500 responses

### 9️⃣ Production Checklist

- [ ] Remove console.logs
- [ ] Add proper error boundaries
- [ ] Add loading spinners/skeletons
- [ ] Add success/error toasts (thay vì alert())
- [ ] Optimize images (lazy loading, compression)
- [ ] Add request timeouts
- [ ] Add retry logic cho failed requests
- [ ] Security: Validate all user inputs
- [ ] Security: Sanitize data before display (XSS prevention)
- [ ] Performance: Debounce search inputs
- [ ] Performance: Paginate large lists
- [ ] Accessibility: Add ARIA labels
- [ ] Accessibility: Keyboard navigation
- [ ] SEO: Add meta tags
- [ ] Analytics: Track user actions

---

## 🚀 DEPLOYMENT & PRODUCTION

### Environment Variables

**Development** (`.env.local`):
```
VITE_API_BASE_URL=https://xxx.execute-api.ap-southeast-1.amazonaws.com/prod
```

**Production** (Hosting provider):
- Vercel: Environment Variables section
- Netlify: Site settings → Build & deploy → Environment
- AWS Amplify: Environment variables tab

### AWS Lambda Environment Variables

**Recommended for Production**:

1. **JWT_SECRET**: Di chuyển từ hard-code sang environment variable
   ```
   Lambda → Configuration → Environment variables
   Key: JWT_SECRET
   Value: <your-secure-random-secret>
   ```

2. **CORS_ORIGIN**: Restrict CORS đến specific domain
   ```
   Key: CORS_ORIGIN
   Value: https://yourdomain.com
   ```

3. Update Lambda code:
   ```javascript
   const JWT_SECRET = process.env.JWT_SECRET;
   const CORS_ORIGIN = process.env.CORS_ORIGIN || '*';
   
   headers: {
     "Access-Control-Allow-Origin": CORS_ORIGIN
   }
   ```

### Monitoring & Logging

1. **CloudWatch Logs**: 
   - Lambda → Monitor → View logs in CloudWatch
   - Set up log retention (30 days recommended)

2. **CloudWatch Alarms**:
   - Set alarm cho Lambda errors
   - Set alarm cho high duration/cold starts
   - Set alarm cho DynamoDB throttling

3. **X-Ray Tracing** (Optional):
   - Enable tracing trong Lambda settings
   - Visualize request flow và identify bottlenecks

### Cost Optimization

1. **Lambda**:
   - Right-size memory (không cần quá 256 MB cho functions này)
   - Reduce cold starts: Use provisioned concurrency nếu cần
   - Monitor invocations: Lambda free tier = 1M requests/month

2. **DynamoDB**:
   - On-demand mode: Good cho unpredictable traffic
   - Monitor capacity: Free tier = 25 GB storage
   - Add backup policies

3. **API Gateway**:
   - Enable caching (optional) để reduce Lambda invocations
   - Free tier = 1M API calls/month

---

## 🔐 SECURITY BEST PRACTICES

### ✅ Đã Implement

- ✅ Password hashing với bcrypt (salt + cost factor 10)
- ✅ JWT token-based authentication
- ✅ JWT expiration (24 hours)
- ✅ HTTPS only (API Gateway force HTTPS)
- ✅ CORS configured
- ✅ Input validation (frontend + backend)
- ✅ No password in responses
- ✅ Generic error messages (không reveal user existence)

### 🔒 Cần Thêm cho Production

1. **Rate Limiting**:
   - API Gateway: Request throttling
   - Lambda: Limit concurrent executions
   - Prevent brute force attacks

2. **JWT Refresh Tokens**:
   - Short-lived access token (15 mins)
   - Long-lived refresh token (7 days)
   - Rotate refresh tokens

3. **AWS Secrets Manager**:
   - Lưu JWT_SECRET trong Secrets Manager
   - Lambda access secret via IAM role

4. **API Key** (Optional):
   - API Gateway: Require API key cho requests
   - Distribute keys carefully

5. **WAF (Web Application Firewall)**:
   - Protect against SQL injection, XSS
   - Rate-based rules
   - Geo-blocking if needed

6. **DynamoDB Encryption**:
   - Enable encryption at rest
   - Use AWS KMS keys

7. **MFA** (Multi-Factor Authentication):
   - Add OTP/SMS verification
   - Use AWS Cognito (advanced)

---

## 💡 NEXT STEPS & ADVANCED FEATURES

### 📚 Học thêm về các topics

1. **AWS Cognito**: Managed authentication service
2. **AWS AppSync**: GraphQL API thay vì REST
3. **Lambda Authorizers**: Custom JWT validation trong API Gateway
4. **DynamoDB Streams**: Trigger Lambda on data changes
5. **Step Functions**: Orchestrate complex workflows
6. **EventBridge**: Event-driven architecture
7. **SQS/SNS**: Message queues và notifications
8. **S3**: Image upload cho product photos

### 🚀 Features để thêm vào project

1. **Admin Dashboard**:
   - Manage products (CRUD)
   - View all orders
   - Update order status
   - View analytics

2. **Email Notifications**:
   - SES: Send welcome email after register
   - Order confirmation emails
   - Password reset emails

3. **Search & Filter**:
   - DynamoDB Query with filters
   - Elasticsearch integration
   - Full-text search

4. **Reviews & Ratings**:
   - Add review system
   - Star ratings
   - Review moderation

5. **Payment Integration**:
   - Stripe/PayPal
   - Payment intent Lambda
   - Webhook handling

6. **Real-time Updates**:
   - WebSocket API
   - Order status updates
   - Live chat support

### 🏗️ Infrastructure as Code

**Terraform Labs** (Coming soon):
- Setup tất cả resources bằng Terraform
- Version control infrastructure
- Multi-environment (dev/staging/prod)
- Automated deployments

Folder structure đã được chuẩn bị: `terraform/`

---

## 📖 TÀI LIỆU THAM KHẢO

### AWS Documentation

- [AWS Lambda Developer Guide](https://docs.aws.amazon.com/lambda/latest/dg/welcome.html)
- [Amazon DynamoDB Developer Guide](https://docs.aws.amazon.com/dynamodb/latest/developerguide/)
- [Amazon API Gateway Developer Guide](https://docs.aws.amazon.com/apigateway/latest/developerguide/)
- [AWS IAM User Guide](https://docs.aws.amazon.com/IAM/latest/UserGuide/)
- [AWS SDK for JavaScript v3](https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/)

### Security & Best Practices

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [JWT Best Practices](https://datatracker.ietf.org/doc/html/rfc8725)
- [Password Storage Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html)
- [AWS Security Best Practices](https://docs.aws.amazon.com/security/)

### Libraries

- [bcryptjs](https://www.npmjs.com/package/bcryptjs)
- [jsonwebtoken](https://www.npmjs.com/package/jsonwebtoken)
- [React Documentation](https://react.dev/)
- [React Router](https://reactrouter.com/)

---

## 🎓 Kết luận

Qua 5 LAB này, bạn đã xây dựng thành công một backend production-ready với:

✅ **Serverless Architecture** sử dụng AWS Lambda, DynamoDB, API Gateway
✅ **Security** với password hashing và JWT authentication
✅ **Scalability** với AWS managed services (auto-scaling)
✅ **Modern development** với ES Modules, async/await
✅ **Best practices** về error handling, validation, logging
✅ **Full-stack integration** giữa React frontend và AWS backend

**Bạn giờ đã có kinh nghiệm để**:
- Build serverless applications
- Design RESTful APIs
- Implement secure authentication
- Work với AWS cloud services
- Integrate frontend với backend

**Tiếp theo**: Practice thêm, thêm features, và deploy lên production!

🎉 **Chúc mừng bạn đã hoàn thành Coffee Shop Backend LAB Series!**

---

📝 *Document version: 1.0 - Completed on February 10, 2026*
