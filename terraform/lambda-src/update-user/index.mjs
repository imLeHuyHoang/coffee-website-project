// ==============================================================================
// Lambda: coffee-update-user
// ==============================================================================
// Cap nhat thong tin nguoi dung (name, phone, address).
// Khong cho phep thay doi email va password qua endpoint nay.
//
// Endpoint: PUT /auth/profile
// Headers: Authorization: Bearer <token>
// Input body: { name?, phone?, address? }
// Output: { user: {...} }
//
// Dependencies: jsonwebtoken (tu Lambda Layer)
// ==============================================================================

import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import {
  DynamoDBDocumentClient,
  GetCommand,
  UpdateCommand,
} from "@aws-sdk/lib-dynamodb";
import jwt from "jsonwebtoken";

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

const TABLE_NAME = process.env.USERS_TABLE || "CoffeeUsers";
const JWT_SECRET = process.env.JWT_SECRET || "your-secret-key";

export const handler = async (event) => {
  try {
    // Verify JWT token
    const authHeader = event.headers?.Authorization || event.headers?.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return {
        statusCode: 401,
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ message: "Unauthorized: Missing or invalid token" }),
      };
    }

    const token = authHeader.substring(7);
    let decoded;
    try {
      decoded = jwt.verify(token, JWT_SECRET);
    } catch (err) {
      return {
        statusCode: 401,
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ message: "Unauthorized: Invalid token" }),
      };
    }

    const userId = decoded.userId;

    // Get current user data
    const getUserResult = await docClient.send(
      new GetCommand({
        TableName: TABLE_NAME,
        Key: { userId },
      })
    );

    if (!getUserResult.Item) {
      return {
        statusCode: 404,
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ message: "User not found" }),
      };
    }

    // Parse update data
    const body = JSON.parse(event.body);
    const { name, phone, address } = body;

    // Build update expression
    const updateExpressions = [];
    const expressionAttributeNames = {};
    const expressionAttributeValues = {};

    if (name !== undefined) {
      updateExpressions.push("#name = :name");
      expressionAttributeNames["#name"] = "name";
      expressionAttributeValues[":name"] = name;
    }

    if (phone !== undefined) {
      updateExpressions.push("#phone = :phone");
      expressionAttributeNames["#phone"] = "phone";
      expressionAttributeValues[":phone"] = phone;
    }

    if (address !== undefined) {
      updateExpressions.push("#address = :address");
      expressionAttributeNames["#address"] = "address";
      expressionAttributeValues[":address"] = address;
    }

    // Always update updatedAt
    updateExpressions.push("#updatedAt = :updatedAt");
    expressionAttributeNames["#updatedAt"] = "updatedAt";
    expressionAttributeValues[":updatedAt"] = Date.now();

    if (updateExpressions.length === 1) {
      return {
        statusCode: 400,
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ message: "No valid fields to update" }),
      };
    }

    // Update user in DynamoDB
    const updateResult = await docClient.send(
      new UpdateCommand({
        TableName: TABLE_NAME,
        Key: { userId },
        UpdateExpression: `SET ${updateExpressions.join(", ")}`,
        ExpressionAttributeNames: expressionAttributeNames,
        ExpressionAttributeValues: expressionAttributeValues,
        ReturnValues: "ALL_NEW",
      })
    );

    // Remove passwordHash before returning
    const { passwordHash, ...userWithoutPassword } = updateResult.Attributes;

    return {
      statusCode: 200,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "Content-Type,Authorization",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ user: userWithoutPassword }),
    };
  } catch (error) {
    console.error("Error updating user:", error);
    return {
      statusCode: 500,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: "Internal server error",
        error: error.message,
      }),
    };
  }
};
