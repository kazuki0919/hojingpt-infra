const functions = require('@google-cloud/functions-framework');

functions.cloudEvent('main', cloudEvent => {
  console.log(`[DEBUG] ${JSON.stringify(cloudEvent)}`);
});
