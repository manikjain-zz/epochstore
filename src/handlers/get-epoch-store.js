// Import dynamodb from aws-sdk
const dynamodb = require('aws-sdk/clients/dynamodb');

// Initialise a dynamodb client
const docClient = new dynamodb.DocumentClient();

// Get the DynamoDB table name from environment variables
const tableName = process.env.DBTable;

// Method to get a list of all items in the DB
exports.handler = async (event, context) => {
    const { path } = event;

    // All log statements are written to CloudWatch by default. For more information, see
    // https://docs.aws.amazon.com/lambda/latest/dg/nodejs-prog-model-logging.html
    console.log('received:', JSON.stringify(event));

    // get all items from the table (only first 1MB data, you can use `LastEvaluatedKey` to get the rest of data)
    // https://docs.aws.amazon.com/AWSJavaScriptSDK/latest/AWS/DynamoDB/DocumentClient.html#scan-property
    // https://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_Scan.html
    const params = { TableName: tableName };
    const { Items } = await docClient.scan(params).promise();

    const response = {
        statusCode: 200,
        body: JSON.stringify(Items),
    };

    console.log(`response from: ${path} statusCode: ${response.statusCode} body: ${response.body}`);
    return response;
};