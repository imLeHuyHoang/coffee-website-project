// ==============================================================================
// Lambda: coffee-register-user
// ==============================================================================
// Dang ky tai khoan moi. Hash password voi bcryptjs, luu vao DynamoDB,
// tra ve JWT token.
//
// Endpoint: POST /auth/register
// Input body: { email, password, name, phone }
// Output: { user: {...}, token: "..." }
//
// Dependencies: bcryptjs, jsonwebtoken (tu Lambda Layer)
// ==============================================================================

import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import {
  DynamoDBDocumentClient,
  PutCommand,
  QueryCommand,
} from "@aws-sdk/lib-dynamodb";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

const TABLE_NAME = process.env.USERS_TABLE || "CoffeeUsers";
const JWT_SECRET = process.env.JWT_SECRET || "your-secret-key";

export const handler = async (event) => {
  try {
    const body = JSON.parse(event.body);
    const { email, password, name, phone } = body;

    // Kiem tra email da ton tai chua (su dung GSI email-index)
    const existing = await docClient.send(
      new QueryCommand({
        TableName: TABLE_NAME,
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
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ message: "Email already exists" }),
      };
    }

    // Hash password voi bcrypt (salt rounds = 10)
    // bcrypt tu dong tao salt va luu kem trong hash string
    const passwordHash = await bcrypt.hash(password, 10);

    // Tao user object
    const user = {
      userId: `user-${Date.now()}`,
      email,
      passwordHash,
      name: name || "",
      phone: phone || "",
      role: "customer",
      createdAt: Date.now(),
      updatedAt: Date.now(),
    };

    // Luu user vao DynamoDB
    await docClient.send(
      new PutCommand({
        TableName: TABLE_NAME,
        Item: user,
      })
    );

    // Tao JWT token (het han sau 7 ngay)
    const token = jwt.sign(
      { userId: user.userId, email: user.email, role: user.role },
      JWT_SECRET,
      { expiresIn: "7d" }
    );

    // Xoa passwordHash truoc khi tra ve client (bao mat)
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
    console.error("Error registering user:", error);
    return {
      statusCode: 500,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: "Error registering user",
        error: error.message,
      }),
    };
  }
};
