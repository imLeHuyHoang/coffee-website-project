// ==============================================================================
// Lambda: coffee-create-order
// ==============================================================================
// Tao don hang moi va luu vao DynamoDB table CoffeeOrders.
//
// Endpoint: POST /orders
// Input body: { orderId?, userId?, customerInfo, items, totalPrice, totalQuantity }
// Output: { message: "Order created", order: {...} }
// ==============================================================================

import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, PutCommand } from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

const TABLE_NAME = process.env.ORDERS_TABLE || "CoffeeOrders";

export const handler = async (event) => {
  try {
    const body = JSON.parse(event.body);

    const order = {
      orderId: body.orderId || `order-${Date.now()}`,
      userId: body.userId || null,
      customerInfo: body.customerInfo,
      items: body.items,
      totalPrice: body.totalPrice,
      totalQuantity: body.totalQuantity,
      status: "pending",
      createdAt: Date.now(),
      updatedAt: Date.now(),
    };

    // PutCommand tao item moi trong DynamoDB
    // Neu orderId da ton tai, item cu se bi GOI DE (overwrite)
    await docClient.send(
      new PutCommand({
        TableName: TABLE_NAME,
        Item: order,
      })
    );

    return {
      statusCode: 200,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "Content-Type,Authorization",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ message: "Order created", order }),
    };
  } catch (error) {
    console.error("Error creating order:", error);
    return {
      statusCode: 500,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: "Error creating order",
        error: error.message,
      }),
    };
  }
};
