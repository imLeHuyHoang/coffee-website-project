// ==============================================================================
// Lambda: coffee-login-user
// ==============================================================================
// Dang nhap: kiem tra email + password, tra ve JWT token.
//
// Endpoint: POST /auth/login
// Input body: { email, password }
// Output: { user: {...}, token: "..." }
//
// Dependencies: bcryptjs, jsonwebtoken (tu Lambda Layer)
// ==============================================================================

import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, QueryCommand } from "@aws-sdk/lib-dynamodb";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

const TABLE_NAME = process.env.USERS_TABLE || "CoffeeUsers";
const JWT_SECRET = process.env.JWT_SECRET || "your-secret-key";

export const handler = async (event) => {
  try {
    const body = JSON.parse(event.body);
    const { email, password } = body;

    // Tim user theo email (su dung GSI email-index)
    const result = await docClient.send(
      new QueryCommand({
        TableName: TABLE_NAME,
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
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ message: "Invalid email or password" }),
      };
    }

    const user = result.Items[0];

    // So sanh password voi hash da luu
    // bcrypt.compare tu dong extract salt tu hash va so sanh
    const isValid = await bcrypt.compare(password, user.passwordHash);
    if (!isValid) {
      return {
        statusCode: 401,
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ message: "Invalid email or password" }),
      };
    }

    // Tao JWT token
    const token = jwt.sign(
      { userId: user.userId, email: user.email, role: user.role },
      JWT_SECRET,
      { expiresIn: "7d" }
    );

    // Xoa passwordHash truoc khi tra ve
    const { passwordHash: _, ...userWithoutPassword } = user;

    return {
      statusCode: 200,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "Content-Type,Authorization",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ user: userWithoutPassword, token }),
    };
  } catch (error) {
    console.error("Error logging in:", error);
    return {
      statusCode: 500,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: "Error logging in",
        error: error.message,
      }),
    };
  }
};
