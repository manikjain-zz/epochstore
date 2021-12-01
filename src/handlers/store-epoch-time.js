// Import dynamodb from aws-sdk
const dynamodb = require('aws-sdk/clients/dynamodb');

// Initialise a dynamodb client
const docClient = new dynamodb.DocumentClient();

// Get the DynamoDB table name from environment variables
const tableName = process.env.DBTable;

// Get the region name from environment variables
const region = process.env.Region

// Method to add an entry to the DB with the current epoch time and source IP
exports.handler = async (event, context) => {

    const { requestContext, path } = event;
    // const sourceIp = requestContext.identity.sourceIp;
    const epochTime = requestContext.requestTimeEpoch;

    // All log statements are written to CloudWatch by default. For more information, see
    // https://docs.aws.amazon.com/lambda/latest/dg/nodejs-prog-model-logging.html
    console.log('received:', JSON.stringify(event));

    // Creates a new item, or replaces an old item with a new item
    // https://docs.aws.amazon.com/AWSJavaScriptSDK/latest/AWS/DynamoDB/DocumentClient.html#put-property
    const params = {
        TableName: tableName,
        Item: { 
            'id': context.awsRequestId, 
            'epoch_time': epochTime, 
            // 'source_ip': sourceIp, 
            'region': region 
        },
    };
    await docClient.put(params).promise();

    const response = {
        statusCode: 200,
        body: JSON.stringify(`${region}: Current epoch time ${epochTime} was stored in the DB.`),
    };

    console.log(`response from: ${path} statusCode: ${response.statusCode} body: ${response.body}`);
    return response;
};