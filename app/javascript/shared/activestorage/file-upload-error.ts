// Error while reading the file client-side
export const ERROR_CODE_READ = 'file-upload-read-error';
// Error while creating the empty blob on the server
export const ERROR_CODE_CREATE = 'file-upload-create-error';
// Error while uploading the blob content
export const ERROR_CODE_STORE = 'file-upload-store-error';
// Error while attaching the blob to the record
export const ERROR_CODE_ATTACH = 'file-upload-attach-error';

// Failure on the client side (syntax error, error reading file, etc.)
export const FAILURE_CLIENT = 'file-upload-failure-client';
// Failure on the server side (typically non-200 response)
export const FAILURE_SERVER = 'file-upload-failure-server';
// Failure during the transfert (request aborted, connection lost, etc)
export const FAILURE_CONNECTIVITY = 'file-upload-failure-connectivity';

/**
  Represent an error during a file upload.
  */
export class FileUploadError extends Error {
  status?: number;
  code?: string;

  constructor(message: string, status: number | undefined, code?: string) {
    super(message);

    this.name = 'FileUploadError';
    this.status = status;
    this.code = code;

    // Prevent the constructor stacktrace from being included.
    // (it messes up with Sentry issues grouping)
    const hasCaptureStackTrace = 'captureStackTrace' in Error;
    if (!hasCaptureStackTrace) {
      this.stack = new Error().stack;
    }
  }

  /**
    Return the component responsible of the error (client, server or connectivity).
    See FAILURE_* constants for values.
    */
  get failureReason() {
    const isNetworkError = this.code && this.code != ERROR_CODE_READ;

    if (isNetworkError && this.status != 0) {
      return FAILURE_SERVER;
    } else if (isNetworkError && this.status == 0) {
      return FAILURE_CONNECTIVITY;
    } else {
      return FAILURE_CLIENT;
    }
  }
}

// Convert an error message returned by DirectUpload to a proper error object.
//
// This function has two goals:
// 1. Remove the file name from the DirectUpload error message
//   (because the filename confuses Sentry error grouping)
// 2. Create each kind of error on a different line
//   (so that Sentry knows they are different kind of errors, from
//   the line they were created.)
export function errorFromDirectUploadMessage(messageOrError: string | Error) {
  const message =
    typeof messageOrError == 'string' ? messageOrError : messageOrError.message;
  const matches = message.match(/ Status: ([0-9]{1,3})/);
  const status = matches ? parseInt(matches[1], 10) : undefined;

  // prettier-ignore
  if (message.includes('Error reading')) {
    return new FileUploadError('Error reading file.', status, ERROR_CODE_READ);
  } else if (message.includes('Error creating')) {
    return new FileUploadError('Error creating file.', status, ERROR_CODE_CREATE);
  } else if (message.includes('Error storing')) {
    return new FileUploadError('Error storing file.', status, ERROR_CODE_STORE);
  } else {
    return new FileUploadError(message, status, undefined);
  }
}
