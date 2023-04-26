const functions = require('@google-cloud/functions-framework');

functions.cloudEvent('main', cloudEvent => {
  console.log(`[DEBUG] cloudEvent: ${JSON.stringify(cloudEvent)}`);

  const rawdata = cloudEvent.data && cloudEvent.data.message.data;
  if (!rawdata) {
    console.warn('Unexpected message format');
    return;
  }

  const message = Buffer.from(rawdata, 'base64').toString('utf-8');
  console.log(`[DEBUG] message: ${message}`);

  // if (typeof message !== 'string') {
  //   console.warn('Unexpected message format');
  //   return;
  // } else if (typeof message === 'object') {
  //   console.warn('Unexpected message format');
  //   return;
  // }
});
