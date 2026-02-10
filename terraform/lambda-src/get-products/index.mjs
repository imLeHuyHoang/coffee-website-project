// ==============================================================================
// Lambda: coffee-get-products
// ==============================================================================
// Lay danh sach tat ca san pham tu DynamoDB table CoffeeProducts.
// Su dung ScanCommand de doc toan bo table (phu hop khi so luong san pham < 1000)
//
// Endpoint: GET /products
// Input: Khong can body hay query params
// Output: { products: [...] }
// ==============================================================================

import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, ScanCommand } from "@aws-sdk/lib-dynamodb";

// Tao DynamoDB client
// Region lay tu environment variable (set boi Terraform)
const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

// Table name tu environment variable (linh hoat, khong hardcode)
const TABLE_NAME = process.env.PRODUCTS_TABLE || "CoffeeProducts";

export const handler = async (event) => {
  try {
    // ScanCommand doc TOAN BO table
    // Luu y: Scan co gioi han 1MB per request
    // Neu table lon (>1MB), can dung pagination voi LastEvaluatedKey
    const result = await docClient.send(
      new ScanCommand({
        TableName: TABLE_NAME,
      })
    );

    return {
      statusCode: 200,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "Content-Type,Authorization",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ products: result.Items }),
    };
  } catch (error) {
    console.error("Error fetching products:", error);
    return {
      statusCode: 500,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: "Error fetching products",
        error: error.message,
      }),
    };
  }
};
