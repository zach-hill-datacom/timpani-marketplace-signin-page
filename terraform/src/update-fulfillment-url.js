const { MarketplaceCatalogClient, DescribeEntityCommand, StartChangeSetCommand } = require("@aws-sdk/client-marketplace-catalog");
const response = require('cfn-response');

exports.handler = async (event, context) => {
  console.log("REQUEST RECEIVED:\n" + JSON.stringify(event));
  const client = new MarketplaceCatalogClient({ region: 'us-east-1' });
  const productId = event.ResourceProperties.ProductId;
  const fulfillmentUrl = event.ResourceProperties.FulfillmentUrl;
  
  try {
    if (event.RequestType === 'Create' || event.RequestType === 'Update') {
      let command = new DescribeEntityCommand({
        Catalog: 'AWSMarketplace',
        EntityId: productId,
        EntityType: 'Product'
      });
      let resp = await client.send(command);
      console.debug("DescribeEntityCommand:\n" + JSON.stringify(resp));
      
      const fulfillmentUrlID = resp.DetailsDocument.Versions[0].DeliveryOptions[0].Id
      console.debug("FullfilmentId:\n" + fulfillmentUrlID);
      
      const details = { 
        DeliveryOptions : [{
          Id: fulfillmentUrlID,
          Details: {
            SaaSUrlDeliveryOptionDetails: {
              FulfillmentUrl: fulfillmentUrl
            }
          }
        }]
      };
      console.debug("details:\n" + JSON.stringify(details));
      
      const startChangeSetInput = { 
        Catalog: 'AWSMarketplace',
        ChangeSet: [ 
          { 
            ChangeType: 'UpdateDeliveryOptions',
            Entity: {
              Identifier: productId,
              Type: 'SaaSProduct@1.0'
            },
            Details: JSON.stringify(details)
          }
        ]
      };
      console.debug("startChangeSetInput:\n" + JSON.stringify(startChangeSetInput));
      
      command = new StartChangeSetCommand(startChangeSetInput);
      resp = await client.send(command);
      console.debug("StartChangeSetResp: \n" + JSON.stringify(resp));

      const responseData = {
        StartChangeSetResp: JSON.stringify(resp)
      };

      await response.send(event, context, 'SUCCESS', responseData);
    } else if (event.RequestType === 'Delete') {
      await response.send(event, context, 'SUCCESS', {});
    } else {
      await response.send(event, context, 'FAILED', { error: 'Invalid request type' });
    }
  } catch (error) {
    console.error('Error:', error);
    await response.send(event, context, 'FAILED', { error: 'Failed to update fulfillment url' });
  }
};