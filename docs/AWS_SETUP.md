# AWS Setup Guide - Coffee Shop Project

Hướng dẫn chi tiết từng bước để setup infrastructure trên AWS Console.

## 📋 Prerequisites

- Tài khoản AWS
- AWS CLI installed và configured
- Basic knowledge về AWS services

## 🎯 Tổng quan kiến trúc

```
Frontend (S3 + CloudFront)
    ↓
API Gateway (REST API)
    ↓
Lambda Functions (8 functions)
    ↓
DynamoDB Tables (4 tables)
    ↓
S3 (images) + SES (emails)
```

---

## PHẦN 1: DynamoDB Tables

### 1.1 Tạo bảng Orders

1. Truy cập **DynamoDB Console**
2. Click **Create table**
3. Điền thông tin:
   - **Table name**: `CoffeeOrders`
   - **Partition key**: `orderId` (String)
   - **Sort key**: `createdAt` (Number)
4. Table settings: **On-demand** (recommended)
5. Click **Create table**
6. Sau khi tạo xong, vào tab **Indexes**
7. Click **Create index**:
   - **Partition key**: `userId` (String)
   - **Sort key**: `createdAt` (Number)
   - **Index name**: `userId-index`
   - **Attribute projections**: All
8. Click **Create index**

### 1.2 Tạo bảng Products

1. Click **Create table**
2. Điền thông tin:
   - **Table name**: `CoffeeProducts`
   - **Partition key**: `productId` (String)
   - **Table settings**: On-demand
3. Click **Create table**

### 1.3 Tạo bảng Reviews

1. Click **Create table**
2. Điền thông tin:
   - **Table name**: `CoffeeReviews`
   - **Partition key**: `reviewId` (String)
   - **Sort key**: `productId` (String)
   - **Table settings**: On-demand
3. Click **Create table**
4. Tạo GSI:
   - **Partition key**: `productId` (String)
   - **Index name**: `productId-index`
   - **Attribute projections**: All

### 1.4 Tạo bảng Users

1. Click **Create table**
2. Điền thông tin:
   - **Table name**: `CoffeeUsers`
   - **Partition key**: `userId` (String)
   - **Table settings**: On-demand
3. Click **Create table**
4. Tạo GSI:
   - **Partition key**: `email` (String)
   - **Index name**: `email-index`
   - **Attribute projections**: All

---

## PHẦN 2: IAM Role cho Lambda

### 2.1 Tạo IAM Policy

1. Truy cập **IAM Console**
2. Click **Policies** → **Create policy**
3. Tab **JSON**, paste policy sau:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": [
        "arn:aws:dynamodb:ap-southeast-1:*:table/Coffee*",
        "arn:aws:dynamodb:ap-southeast-1:*:table/Coffee*/index/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject"
      ],
      "Resource": "arn:aws:s3:::coffee-shop-images/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ses:SendEmail",
        "ses:SendRawEmail"
      ],
      "Resource": "*"
    }
  ]
}
```

4. Click **Next**
5. **Policy name**: `CoffeeLambdaPolicy`
6. Click **Create policy**

### 2.2 Tạo IAM Role

1. Click **Roles** → **Create role**
2. **Trusted entity type**: AWS service
3. **Use case**: Lambda
4. Click **Next**
5. Attach policies:
   - `CoffeeLambdaPolicy` (vừa tạo)
   - `AWSLambdaBasicExecutionRole` (AWS managed)
6. **Role name**: `CoffeeLambdaRole`
7. Click **Create role**

---

## PHẦN 3: Lambda Functions

Tạo tất cả 8 Lambda functions sau. Mỗi function làm theo các bước:

### 3.1 Lambda: coffee-create-order

1. Truy cập **Lambda Console**
2. Click **Create function**
3. Điền thông tin:
   - **Function name**: `coffee-create-order`
   - **Runtime**: Node.js 20.x
   - **Execution role**: Use existing role → `CoffeeLambdaRole`
4. Click **Create function**
5. Code editor, paste code:

```javascript
const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, PutCommand } = require("@aws-sdk/lib-dynamodb");

const client = new DynamoDBClient({ region: "ap-southeast-1" });
const docClient = DynamoDBDocumentClient.from(client);

exports.handler = async (event) => {
  try {
    const body = JSON.parse(event.body);
    
    const order = {
      orderId: body.orderId || `order-${Date.now()}`,
      userId: body.userId || null,
      customerInfo: body.customerInfo,
      items: body.items,
      totalPrice: body.totalPrice,
      totalQuantity: body.totalQuantity,
      status: 'pending',
      createdAt: Date.now(),
      updatedAt: Date.now(),
    };

    await docClient.send(
      new PutCommand({
        TableName: "CoffeeOrders",
        Item: order,
      })
    );

    return {
      statusCode: 200,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "*",
      },
      body: JSON.stringify({ message: "Order created", order }),
    };
  } catch (error) {
    console.error(error);
    return {
      statusCode: 500,
      headers: {
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify({ message: "Error creating order", error: error.message }),
    };
  }
};
```

6. Click **Deploy**
7. Tab **Configuration** → **Environment variables**:
   - Key: `ORDERS_TABLE`, Value: `CoffeeOrders`
8. Tab **Configuration** → **General configuration**:
   - Timeout: 30 seconds

### 3.2 Lambda: coffee-get-orders

Tương tự, tạo function với code:

```javascript
const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, QueryCommand, ScanCommand } = require("@aws-sdk/lib-dynamodb");

const client = new DynamoDBClient({ region: "ap-southeast-1" });
const docClient = DynamoDBDocumentClient.from(client);

exports.handler = async (event) => {
  try {
    const userId = event.queryStringParameters?.userId;

    let result;
    if (userId) {
      // Query by userId
      result = await docClient.send(
        new QueryCommand({
          TableName: "CoffeeOrders",
          IndexName: "userId-index",
          KeyConditionExpression: "userId = :userId",
          ExpressionAttributeValues: {
            ":userId": userId,
          },
        })
      );
    } else {
      // Get all orders (admin)
      result = await docClient.send(
        new ScanCommand({
          TableName: "CoffeeOrders",
        })
      );
    }

    return {
      statusCode: 200,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "*",
      },
      body: JSON.stringify({ orders: result.Items }),
    };
  } catch (error) {
    console.error(error);
    return {
      statusCode: 500,
      headers: {
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify({ message: "Error fetching orders", error: error.message }),
    };
  }
};
```

### 3.3 Lambda: coffee-get-products

```javascript
const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, ScanCommand } = require("@aws-sdk/lib-dynamodb");

const client = new DynamoDBClient({ region: "ap-southeast-1" });
const docClient = DynamoDBDocumentClient.from(client);

exports.handler = async (event) => {
  try {
    const result = await docClient.send(
      new ScanCommand({
        TableName: "CoffeeProducts",
      })
    );

    return {
      statusCode: 200,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "*",
      },
      body: JSON.stringify({ products: result.Items }),
    };
  } catch (error) {
    console.error(error);
    return {
      statusCode: 500,
      headers: {
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify({ message: "Error fetching products", error: error.message }),
    };
  }
};
```

### 3.4 Lambda: coffee-register-user

```javascript
const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, PutCommand, QueryCommand } = require("@aws-sdk/lib-dynamodb");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");

const client = new DynamoDBClient({ region: "ap-southeast-1" });
const docClient = DynamoDBDocumentClient.from(client);

const JWT_SECRET = process.env.JWT_SECRET || "your-secret-key";

exports.handler = async (event) => {
  try {
    const body = JSON.parse(event.body);
    const { email, password, name, phone } = body;

    // Check if user exists
    const existing = await docClient.send(
      new QueryCommand({
        TableName: "CoffeeUsers",
        IndexName: "email-index",
        KeyConditionExpression: "email = :email",
        ExpressionAttributeValues: {
          ":email": email,
        },
      })
    );

    if (existing.Items && existing.Items.length > 0) {
      return {
        statusCode: 400,
        headers: { "Access-Control-Allow-Origin": "*" },
        body: JSON.stringify({ message: "Email đã tồn tại" }),
      };
    }

    // Hash password
    const passwordHash = await bcrypt.hash(password, 10);

    // Create user
    const user = {
      userId: `user-${Date.now()}`,
      email,
      passwordHash,
      name,
      phone,
      role: "customer",
      createdAt: Date.now(),
      updatedAt: Date.now(),
    };

    await docClient.send(
      new PutCommand({
        TableName: "CoffeeUsers",
        Item: user,
      })
    );

    // Generate JWT
    const token = jwt.sign(
      { userId: user.userId, email: user.email, role: user.role },
      JWT_SECRET,
      { expiresIn: "7d" }
    );

    // Remove password hash before sending
    delete user.passwordHash;

    return {
      statusCode: 200,
      headers: { "Access-Control-Allow-Origin": "*" },
      body: JSON.stringify({ user, token }),
    };
  } catch (error) {
    console.error(error);
    return {
      statusCode: 500,
      headers: { "Access-Control-Allow-Origin": "*" },
      body: JSON.stringify({ message: "Error registering user", error: error.message }),
    };
  }
};
```

**Note**: Để sử dụng bcryptjs và jsonwebtoken, cần package lại Lambda với dependencies. Xem phần "Lambda Layers" bên dưới.

### 3.5 Lambda: coffee-login-user

```javascript
const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, QueryCommand } = require("@aws-sdk/lib-dynamodb");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");

const client = new DynamoDBClient({ region: "ap-southeast-1" });
const docClient = DynamoDBDocumentClient.from(client);

const JWT_SECRET = process.env.JWT_SECRET || "your-secret-key";

exports.handler = async (event) => {
  try {
    const body = JSON.parse(event.body);
    const { email, password } = body;

    // Find user
    const result = await docClient.send(
      new QueryCommand({
        TableName: "CoffeeUsers",
        IndexName: "email-index",
        KeyConditionExpression: "email = :email",
        ExpressionAttributeValues: {
          ":email": email,
        },
      })
    );

    if (!result.Items || result.Items.length === 0) {
      return {
        statusCode: 401,
        headers: { "Access-Control-Allow-Origin": "*" },
        body: JSON.stringify({ message: "Email hoặc mật khẩu không đúng" }),
      };
    }

    const user = result.Items[0];

    // Verify password
    const isValid = await bcrypt.compare(password, user.passwordHash);
    if (!isValid) {
      return {
        statusCode: 401,
        headers: { "Access-Control-Allow-Origin": "*" },
        body: JSON.stringify({ message: "Email hoặc mật khẩu không đúng" }),
      };
    }

    // Generate JWT
    const token = jwt.sign(
      { userId: user.userId, email: user.email, role: user.role },
      JWT_SECRET,
      { expiresIn: "7d" }
    );

    // Remove password hash
    delete user.passwordHash;

    return {
      statusCode: 200,
      headers: { "Access-Control-Allow-Origin": "*" },
      body: JSON.stringify({ user, token }),
    };
  } catch (error) {
    console.error(error);
    return {
      statusCode: 500,
      headers: { "Access-Control-Allow-Origin": "*" },
      body: JSON.stringify({ message: "Error logging in", error: error.message }),
    };
  }
};
```

### 3.6 Lambda Layers (cho bcryptjs & jsonwebtoken)

**Option 1: Sử dụng Lambda Layer**

1. Trên máy local, tạo thư mục:
```bash
mkdir nodejs
cd nodejs
npm init -y
npm install bcryptjs jsonwebtoken
cd ..
zip -r node_modules.zip nodejs/
```

2. Truy cập **Lambda Console** → **Layers**
3. Click **Create layer**
   - **Name**: `CoffeeNodeModules`
   - **Upload**: `node_modules.zip`
   - **Compatible runtimes**: Node.js 20.x
4. Click **Create**

5. Vào từng Lambda function (register, login)
6. Tab **Code** → Scroll down → **Layers**
7. Click **Add a layer**
8. Chọn **Custom layers** → `CoffeeNodeModules`
9. Click **Add**

**Option 2: Package function code với dependencies**

Tạo thư mục cho từng function, install dependencies rồi zip lại:
```bash
mkdir coffee-register-user
cd coffee-register-user
npm init -y
npm install bcryptjs jsonwebtoken @aws-sdk/client-dynamodb @aws-sdk/lib-dynamodb
# Copy index.js vào đây
zip -r function.zip .
```

Upload `function.zip` vào Lambda function.

---

## PHẦN 4: API Gateway

### 4.1 Tạo REST API

1. Truy cập **API Gateway Console**
2. Click **Create API**
3. Chọn **REST API** (not private)
4. Click **Build**
5. Điền:
   - **API name**: `CoffeeShopAPI`
   - **Endpoint Type**: Regional
6. Click **Create API**

### 4.2 Tạo Resources

**Resource: /orders**

1. Click **Actions** → **Create Resource**
2. **Resource Name**: `orders`
3. **Resource Path**: `/orders`
4. Enable **CORS**: ✅
5. Click **Create Resource**

**Resource: /products**

Tương tự, tạo resource `/products`

**Resource: /auth**

Tương tự, tạo resource `/auth`

**Resource: /auth/register**

1. Click vào `/auth`
2. **Actions** → **Create Resource**
3. **Resource Name**: `register`
4. Enable CORS
5. Click **Create Resource**

**Resource: /auth/login**

Tương tự, tạo `/auth/login`

### 4.3 Tạo Methods

**POST /orders (Tạo đơn hàng)**

1. Click vào resource `/orders`
2. **Actions** → **Create Method** → Chọn **POST**
3. Điền:
   - **Integration type**: Lambda Function
   - **Lambda Function**: `coffee-create-order`
   - **Use Lambda Proxy integration**: ✅
4. Click **Save**
5. Click **OK** (để cho phép API Gateway invoke Lambda)

**GET /orders (Lấy danh sách đơn hàng)**

1. Click vào resource `/orders`
2. **Actions** → **Create Method** → Chọn **GET**
3. Integration với `coffee-get-orders`

**GET /products**

1. Click vào resource `/products`
2. **Actions** → **Create Method** → **GET**
3. Integration với `coffee-get-products`

**POST /auth/register**

1. Click vào `/auth/register`
2. **Actions** → **Create Method** → **POST**
3. Integration với `coffee-register-user`

**POST /auth/login**

1. Click vào `/auth/login`
2. **Actions** → **Create Method** → **POST**
3. Integration với `coffee-login-user`

### 4.4 Enable CORS cho tất cả methods

Đối với mỗi resource:
1. Click vào resource
2. **Actions** → **Enable CORS**
3. Giữ default settings
4. Click **Enable CORS and replace existing CORS headers**

### 4.5 Deploy API

1. **Actions** → **Deploy API**
2. **Deployment stage**: [New Stage]
3. **Stage name**: `prod`
4. Click **Deploy**
5. **Copy Invoke URL** (ví dụ: `https://abc123.execute-api.ap-southeast-1.amazonaws.com/prod`)

### 4.6 Cập nhật Frontend

Mở file `src/config/api.config.js` và update:

```javascript
const API_CONFIG = {
  BASE_URL: 'https://abc123.execute-api.ap-southeast-1.amazonaws.com/prod',
  // ...
};
```

---

## PHẦN 5: S3 for Static Hosting

### 5.1 Tạo S3 Bucket

1. Truy cập **S3 Console**
2. Click **Create bucket**
3. **Bucket name**: `coffee-shop-website-youruniquename`
4. **Region**: ap-southeast-1
5. **Block Public Access**: Uncheck "Block all public access" (⚠️ cẩn thận)
6. Acknowledge warning
7. Click **Create bucket**

### 5.2 Enable Static Website Hosting

1. Click vào bucket vừa tạo
2. Tab **Properties**
3. Scroll xuống **Static website hosting**
4. Click **Edit**
5. **Enable**: Static website hosting
6. **Index document**: `index.html`
7. **Error document**: `index.html` (cho SPA routing)
8. Click **Save changes**

### 5.3 Bucket Policy

1. Tab **Permissions**
2. **Bucket Policy** → **Edit**
3. Paste policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::coffee-shop-website-youruniquename/*"
    }
  ]
}
```

4. Click **Save changes**

### 5.4 Upload Frontend

Build frontend và upload:

```bash
npm run build
aws s3 sync dist/ s3://coffee-shop-website-youruniquename
```

Hoặc upload thủ công qua console:
1. Tab **Objects**
2. Click **Upload**
3. Drag & drop thư mục `dist/`
4. Click **Upload**

### 5.5 Truy cập Website

Website URL: `http://coffee-shop-website-youruniquename.s3-website-ap-southeast-1.amazonaws.com`

---

## PHẦN 6: CloudFront (Optional - CDN)

### 6.1 Tạo Distribution

1. Truy cập **CloudFront Console**
2. Click **Create distribution**
3. **Origin domain**: Chọn S3 bucket website endpoint
4. **Origin path**: để trống
5. **Viewer protocol policy**: Redirect HTTP to HTTPS
6. **Cache policy**: CachingOptimized
7. **Default root object**: `index.html`
8. Click **Create distribution**

### 6.2 Cấu hình Error Pages (cho SPA)

1. Click vào distribution vừa tạo
2. Tab **Error pages**
3. Click **Create custom error response**
   - **HTTP error code**: 403
   - **Customize error response**: Yes
   - **Response page path**: `/index.html`
   - **HTTP Response code**: 200
4. Click **Create**
5. Lặp lại cho error code 404

### 6.3 Invalidate Cache

Mỗi khi update code:

```bash
aws cloudfront create-invalidation --distribution-id YOUR_DIST_ID --paths "/*"
```

---

## PHẦN 7: Testing

### 7.1 Test API với Postman/curl

**Test tạo đơn hàng:**

```bash
curl -X POST https://your-api-url/prod/orders \
-H "Content-Type: application/json" \
-d '{
  "orderId": "test-order-1",
  "customerInfo": {
    "name": "Test User",
    "address": "123 Test St",
    "phone": "0123456789"
  },
  "items": [],
  "totalPrice": 300000,
  "totalQuantity": 1
}'
```

**Test register:**

```bash
curl -X POST https://your-api-url/prod/auth/register \
-H "Content-Type: application/json" \
-d '{
  "email": "test@example.com",
  "password": "password123",
  "name": "Test User",
  "phone": "0123456789"
}'
```

### 7.2 Test Frontend

1. Truy cập website URL
2. Test các chức năng:
   - Xem sản phẩm
   - Thêm vào giỏ hàng
   - Đặt hàng
   - Đăng ký / Đăng nhập
   - Xem lịch sử đơn hàng

---

## 📊 Monitoring

### CloudWatch Logs

Xem logs của Lambda functions:
1. **CloudWatch Console** → **Log groups**
2. Tìm `/aws/lambda/coffee-*`
3. Click vào log stream để xem chi tiết

### CloudWatch Metrics

Monitor Lambda:
- Invocations
- Errors
- Duration
- Throttles

Monitor DynamoDB:
- Read/Write capacity
- Throttled requests

---

## 🔒 Security Best Practices

1. **IAM Roles**: Principle of least privilege
2. **API Gateway**: Enable API keys & usage plans
3. **S3**: Restrict public access, use CloudFront
4. **Lambda**: Set timeout, memory appropriately
5. **DynamoDB**: Enable point-in-time recovery
6. **Secrets**: Use AWS Secrets Manager cho JWT_SECRET

---

## 💰 Cost Optimization

- **Lambda**: Pay per request
- **DynamoDB**: Use on-demand billing mode
- **API Gateway**: First 1M requests free
- **S3**: Use lifecycle policies
- **CloudFront**: Free tier available

**Estimated monthly cost** (low traffic):
- Lambda: $0-5
- DynamoDB: $0-10
- API Gateway: $0-5
- S3: $0-2
- CloudFront: $0-5

**Total**: ~$0-27/month

---

## 🎉 Hoàn thành!

Bạn đã hoàn thành setup Coffee Shop trên AWS. Kiểm tra kỹ các bước và test thật kỹ trước khi production.

**Next steps:**
- Setup monitoring alerts
- Implement CI/CD
- Add more features (Reviews, Admin)
- Convert to Terraform (IaC)

---

📝 **Note**: Document này là bản hướng dẫn console. Để automated setup, xem [TERRAFORM.md](./TERRAFORM.md)
