const { S3Client, PutObjectCommand, DeleteObjectCommand } = require("@aws-sdk/client-s3");
const s3Client = new S3Client();

exports.handler = async function(event, context) {
  console.log("REQUEST RECEIVED:\n" + JSON.stringify(event));
  let responseStatus = "FAILED";
  let responseData = {};
  let physicalResourceId = event.ResourceProperties.Key;
  
  if (event.RequestType == "Delete") {
    console.log(`Deleting s3://${event.ResourceProperties.BucketName}/${event.ResourceProperties.Key}`);
    try {
      const deleteObjectCommand = new DeleteObjectCommand({
        Bucket: event.ResourceProperties.BucketName,
        Key: event.ResourceProperties.Key
      });
      await s3Client.send(deleteObjectCommand);
      responseStatus = "SUCCESS";
      console.log("Deleted");
    } catch (e) {
      console.error(`Failed to delete object: ${e.message}`);
    }
  } else {
    const body = typeof event.ResourceProperties.IsBase64Encoded == "string" && event.ResourceProperties.IsBase64Encoded.toLowerCase() == "true" ? Buffer.from(event.ResourceProperties.Body, 'base64') : event.ResourceProperties.Body;
    console.log(`Saving s3://${event.ResourceProperties.BucketName}/${event.ResourceProperties.Key}`);
    try {
      const putObjectCommand = new PutObjectCommand({
        Body: body,
        Bucket: event.ResourceProperties.BucketName,
        Key: event.ResourceProperties.Key,
        ContentType: event.ResourceProperties.ContentType
      });
      await s3Client.send(putObjectCommand);
      console.log("Saved");
      responseData["BucketName"] = event.ResourceProperties.BucketName;
      responseData["Key"] = event.ResourceProperties.Key;
      responseData["ContentType"] = event.ResourceProperties.ContentType;
      responseStatus = "SUCCESS";
    } catch (e) {
      console.log(`Could not save to S3: ${e.message}`);
    }
  }
  return await sendResponse(event, context, responseStatus, responseData, physicalResourceId);
};

const sendResponse = async function(event, context, responseStatus, responseData, physicalResourceId) {
  let responseBody = JSON.stringify({
    Status: responseStatus,
    Reason: "See the details in CloudWatch Log Stream: " + context.logStreamName,
    PhysicalResourceId: physicalResourceId,
    StackId: event.StackId,
    RequestId: event.RequestId,
    LogicalResourceId: event.LogicalResourceId,
    Data: responseData
  });
  console.log("RESPONSE BODY:\n", responseBody);
  await sendRequest(event.ResponseURL, {
    method: "PUT",
    body: responseBody
  })
};

const sendRequest = async function(url, opt) {
  opt = opt ? opt : {};
  const parsedUrl = require("url").parse(url);
  let headers = opt.headers ? opt.headers : {};
  headers["Content-length"] = opt.body ? opt.body.length : 0;
  const options = {
    hostname: parsedUrl.hostname,
    port: opt.port ? opt.port : (parsedUrl.protocol == "https:" ? 443 : 80),
    path: parsedUrl.path,
    method: opt.method ? opt.method : "GET",
    headers: headers
  };
  let response = await new Promise(function(res, err) {
    let request = require(parsedUrl.protocol == "https:" ? "https" : "http").request(options, function(response) {
      let responseText = [];
      response.on("data", function(d) {
        responseText.push(d);
      });
      response.on("end", function() {
        response.responseText = responseText.join("");
        res(response);
      });
    });
    request.on("error", function(error) {
      console.error("sendRequest Error: " + error);
      err(error);
    });
    request.write(opt.body ? opt.body : "");
    request.end();
  });
  return response;
};