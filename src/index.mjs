import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, PutCommand } from "@aws-sdk/lib-dynamodb";

// Khởi tạo DynamoDB Client
const client = new DynamoDBClient({});
const dynamoDB = DynamoDBDocumentClient.from(client);

// Hàm generate ID đơn giản (tùy ý bạn viết)
const generateId = () =>
  Date.now().toString() + Math.random().toString(36).substring(2);

export const handler = async (event) => {
  // 1. Parse body từ event
  let body;
  try {
    // Nếu là API Gateway Proxy Integration, event.body thường là chuỗi JSON
    body = typeof event === "string" ? JSON.parse(event) : event;
  } catch (err) {
    return {
      statusCode: 400,
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: "Invalid JSON body",
        error: err.message,
      }),
    };
  }

  // 2. Lấy các trường cần thiết từ body
  const { customerInfo, items, totalPrice } = body;

  // Validate cơ bản
  if (!customerInfo || !items || !totalPrice) {
    return {
      statusCode: 400,
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message:
          "Missing required fields: customerInfo, items, and totalPrice are required",
      }),
    };
  }

  // 3. Tự sinh orderID, createdAt, updatedAt
  const orderID = generateId();
  const createdAt = new Date().toISOString();
  const updatedAt = new Date().toISOString();

  // 4. Lưu vào DynamoDB
  const params = {
    TableName: process.env.DYNAMODB_TABLE_NAME || "Orders",
    Item: {
      orderID, // cột chính là orderID (thay vì orderId)
      customerInfo,
      items,
      totalPrice,
      createdAt,
      updatedAt,
    },
  };

  try {
    await dynamoDB.send(new PutCommand(params));

    // Thành công
    return {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: "Order saved successfully",
        orderID, // Trả về cho client biết orderID
      }),
    };
  } catch (err) {
    console.error("DynamoDB error:", err);
    return {
      statusCode: 500,
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: "Error saving order",
        error: err.message,
      }),
    };
  }
};
