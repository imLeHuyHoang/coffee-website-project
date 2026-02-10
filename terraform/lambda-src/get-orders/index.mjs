// ==============================================================================
// Lambda: coffee-get-orders
// ==============================================================================
// Lay danh sach don hang. Neu co userId trong query params -> query theo userId.
// Neu khong -> scan toan bo table (admin).
//
// Endpoint: GET /orders?userId=xxx
// Input: Query string parameter userId (optional)
// Output: { orders: [...] }
// ==============================================================================

import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import {
  DynamoDBDocumentClient,
  QueryCommand,
  ScanCommand,
} from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

const TABLE_NAME = process.env.ORDERS_TABLE || "CoffeeOrders";

export const handler = async (event) => {
  try {
    // API Gateway Lambda Proxy: query params nam trong event.queryStringParameters
    const userId = event.queryStringParameters?.userId;

    let result;
    if (userId) {
      // Query theo userId su dung GSI (Global Secondary Index)
      // GSI "userId-index" cho phep tim kiem theo userId thay vi orderId
      result = await docClient.send(
        new QueryCommand({
          TableName: TABLE_NAME,
          IndexName: "userId-index",
          KeyConditionExpression: "userId = :userId",
          ExpressionAttributeValues: {
            ":userId": userId,
          },
          // Sap xep theo createdAt giam dan (moi nhat truoc)
          ScanIndexForward: false,
        })
      );
    } else {
      // Scan toan bo table (dung cho admin dashboard)
      result = await docClient.send(
        new ScanCommand({
          TableName: TABLE_NAME,
        })
      );
    }

    return {
      statusCode: 200,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "Content-Type,Authorization",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ orders: result.Items }),
    };
  } catch (error) {
    console.error("Error fetching orders:", error);
    return {
      statusCode: 500,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: "Error fetching orders",
        error: error.message,
      }),
    };
  }
};
