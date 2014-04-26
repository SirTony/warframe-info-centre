class Exception

    message  = null;
    code     = null;

    constructor: ( m, c ) ->
        message = m
        code    = c

    getMessage: -> return message
    getCode:    -> return code

    @getType: ( ex ) ->
        if ex instanceof StorageException
            return "StorageException"
        else if ex instanceof ArgumentException
            return "ArgumentException"
        else if ex instanceof WebException
            return "WebException"
        else if ex instanceof AppException
            return "AppException"
        else
            return null;

class ArgumentException extends Exception
class AppException extends Exception
class StorageException extends Exception
class WebException extends Exception