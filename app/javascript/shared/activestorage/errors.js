// Convert an error message returned by DirectUpload to a proper error object.
//
// This function has two goals:
// 1. Remove the file name from the DirectUpload error message
//   (because the filename confuses Sentry error grouping)
// 2. Create each kind of error on a different line
//   (so that Sentry knows they are different kind of errors, from
//   the line they were created.)
export default function errorFromDirectUploadMessage(message) {
  let matches = message.match(/ Status: [0-9]{1,3}/);
  let status = (matches && matches[0]) || '';

  if (message.includes('Error creating')) {
    return new Error('Error creating file.' + status);
  } else if (message.includes('Error storing')) {
    return new Error('Error storing file.' + status);
  } else if (message.includes('Error reading')) {
    return new Error('Error reading file.' + status);
  } else {
    return new Error(message);
  }
}
