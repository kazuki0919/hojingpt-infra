const functions = require('@google-cloud/functions-framework');

// Register a CloudEvent callback with the Functions Framework that will
// be triggered by an Eventarc Cloud Audit Logging trigger.
//
// Note: this is NOT designed for second-party (Cloud Audit Logs -> Pub/Sub) triggers!
functions.cloudEvent('main', cloudEvent => {
  // Print out details from the CloudEvent itself
  console.log('Event type:', cloudEvent.type);

  // Print out the CloudEvent's `subject` property
  // See https://github.com/cloudevents/spec/blob/v1.0.1/spec.md#subject
  console.log('Subject:', cloudEvent.subject);

  console.log(`[DEBUG] msg: ${cloudEvent.data.message}`);

  // Print out details from the `protoPayload`
  // This field encapsulates a Cloud Audit Logging entry
  // See https://cloud.google.com/logging/docs/audit#audit_log_entry_structure
  // const payload = cloudEvent.data && cloudEvent.data.protoPayload;
  // if (payload) {
  //   console.log('API method:', payload.methodName);
  //   console.log('Resource name:', payload.resourceName);
  //   console.log('Principal:', payload.authenticationInfo.principalEmail);
  // }
});
