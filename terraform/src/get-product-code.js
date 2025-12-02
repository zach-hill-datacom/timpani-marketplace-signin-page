const { MarketplaceCatalogClient, DescribeEntityCommand } = require("@aws-sdk/client-marketplace-catalog");
const response = require('cfn-response');

exports.handler = async (event, context) => {
  context.callbackWaitsForEmptyEventLoop = true;
  console.log("REQUEST RECEIVED:\n" + JSON.stringify(event));
  const client = new MarketplaceCatalogClient({ region: 'us-east-1' });
  const productId = event.ResourceProperties.ProductId;

  try {
    if (event.RequestType === 'Create' || event.RequestType === 'Update') {
      const command = new DescribeEntityCommand({
        Catalog: 'AWSMarketplace',
        EntityId: productId,
        EntityType: 'Product'
      });
      const resp = await client.send(command);
      const productCode = resp.DetailsDocument.Description.ProductCode;

      const responseData = {
        ProductCode: productCode
      };

      await response.send(event, context, 'SUCCESS', responseData);
    } else if (event.RequestType === 'Delete') {
      await response.send(event, context, 'SUCCESS', {});
    } else {
      await response.send(event, context, 'FAILED', { error: 'Invalid request type' });
    }
  } catch (error) {
    console.error('Error:', error);
    await response.send(event, context, 'FAILED', { error: 'Failed to fetch product code' });
  }
};