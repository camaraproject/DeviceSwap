Feature: CAMARA Device Swap API, 0.1.0 - Operation checkDeviceSwap

  # Input to be provided by the implementation to the tester
  #
  # Testing assets:
  #
  # References to OAS spec schemas refer to schemas specifies in device_swap.yaml, version 0.1.0
  #
  # Check if device swap has been performed during a past period


    Background: Common checkDeviceSwap setup
        Given the resource "device-swap/v0/check"
        And the header "Content-Type" is set to "application/json"
        And the header "Authorization" is set to a valid access token
        And the header "x-correlator" is set to a UUID value
        And the request body is set by default to a request body compliant with the schema

    # This first scenario serves as a minimum, not testing any specific verificationResult
    @check_device_swap_1_generic_success_scenario
    Scenario: Common validations for any sucess scenario
        Given a valid phone number identified by the token or provided in the request body
        When the request "checkDeviceSwap" is sent
        Then the response status code is 200
        And the response header "Content-Type" is "application/json"
        And the response header "x-correlator" has same value as the request header "x-correlator"
        And the response body complies with the OAS schema at "/components/schemas/CheckDeviceSwapInfo"

  # Scenarios testing specific situations
    @check_device_swap_2_valid_device_swap_no_max_age
    Scenario: Check that the response shows that the device has been swapped using default value for maxAge
        Given a valid phone number identified by the token or provided in the request body
        And the device has been swapped in the last 240 hours
        When the request "checkDeviceSwap" is sent
        Then the response status code is 200
        And the value of response property "$.swapped" == true

    @check_device_swap_3_valid_device_swap_max_age
    Scenario Outline: Check that the response shows that the device has been swapped - maxAge is provided in the request
        Given a valid phone number identified by the token or provided in the request body
        And the device has been swapped in the last "<hours>"
        And the request body property "maxAge" is set to a value equal or greater than "<hours>" within the allowed range
        When the request "checkDeviceSwap" is sent
        Then the response status code is 200
        And the value of response property "$.swapped" == true

        Examples:
            | hours |
            | 260   |
            | 120   |
            | 24    |
            | 12    |

    @check_device_swap_4_more_than_240_hours
    Scenario: Check that the response shows that the device has not been swapped when the last swap was more than 240 hours ago
        Given a valid phone number identified by the token or provided in the request body
        And the device has been swapped more than 240 hours ago
        When the request "checkDeviceSwap" is sent
        Then the response status code is 200
        And the value of response property "$.swapped" == false

    @check_device_swap_5_out_of_max_age
    Scenario: Check that the response shows that the device has not been swapped when the last swap was before the maxAge field
        Given a valid phone number identified by the token or provided in the request body
        And the last swap for this phone number's in the device is known
        And the request body property "maxAge" is set to a value lower that the last known device swap
        When the request "checkDeviceSwap" is sent
        Then the response status code is 200
        And the value of response property "$.swapped" == false

    @check_device_swap_6_no_device_swap_no_max_age
    Scenario: Check that the response shows that the device has not been swapped - maxAge is not provided in the request parameter
        Given a valid phone number identified by the token or provided in the request body
        And the device has never been swapped
        And the sim card has been associated with this device for more than 240 hours
        When the request "checkDeviceSwap" is sent
        Then the response status code is 200
        And the value of response property "$.swapped" == false

    @check_device_swap_7_no_device_swap_with_max_age
    Scenario Outline: Check that the response shows that the device has never been swapped - maxAge is provided in the request
        Given a valid phone number identified by the token or provided in the request body
        And the device has never been swapped
        And the sim card has been associated with this device for more than 240 hours
        And the request body property "maxAge" is set to a value equal or greater than "<hours>" within the allowed range
        When the request "checkDeviceSwap" is sent
        Then the response status code is 200
        And the value of response property "$.swapped" == false

        Examples:
            | hours |
            | 260   |
            | 120   |
            | 24    |
            | 12    |

  # Specific errors

    # This scenario may not apply if the Operators's implementation does not allow a valid access token to be issued for a phone number that has never been connected to the network and, therefore, cannot reach the API.
    @check_device_swap_8_NoDeviceSwapPhoneNumberNeverConnected
    Scenario: Error when the phone number has never connected to the Operators's network so the device has never been activated
        Given a valid phone number provided in the request body
        And the sim for that device has never been connected to the Operator's network
        When the request "checkDeviceSwap" is sent
        Then the response status code is 422
        And the response property "$.status" is 422
        And the response property "$.code" is "NOT_SUPPORTED"
        And the response property "$.message" contains a user friendly text

    @check_device_swap_9_phone_number_not_supported
    Scenario: Error when the service is not supported for the provided phone number
        Given the request body property "$.phoneNumber" is set to a phone number for which the service is not available
        When the request "checkDeviceSwap" is sent
        Then the response status code is 422
        And the response property "$.status" is 422
        And the response property "$.code" is "NOT_SUPPORTED"
        And the response property "$.message" contains a user friendly text

    @check_device_swap_10_phone_number_provided_does_not_match_the_token
    Scenario: Error when the phone number provided in the request body does not match the phone number asssociated with the access token
        Given the request body property "$.phoneNumber" is set to a valid testing phoneNumber that does not match the one associated with the token
        And the header "Authorization" is set to a valid access token
        When the request "checkDeviceSwap" is sent
        Then the response status code is 403
        And the response property "$.status" is 403
        And the response property "$.code" is "INVALID_TOKEN_CONTEXT"
        And the response property "$.message" contains a user friendly text

    @check_device_swap_11_phone_number_not_provided_and_cannot_be_deducted_from_access_token
    Scenario: Error when phone number can not be deducted from access token and it is not provided in the request body
        Given the phone number is neither identified by the token nor provided in the request body
        When the request "checkDeviceSwap" is sent
        Then the response status code is 422
        And the response property "$.status" is 422
        And the response property "$.code" is "UNIDENTIFIABLE_PHONE_NUMBER"
        And the response property "$.message" contains a user friendly text

    @check_device_swap_12_phone_number_not_found
    Scenario: Error when phone number not found
        Given the request body property "$.phoneNumber" is compliant with the schema but does not identify a valid subscription
        When the request "checkDeviceSwap" is sent
        Then the response status code is 404
        And the response property "$.status" is 404
        And the response property "$.code" is "NOT_FOUND"
        And the response property "$.message" contains a user friendly text

    # Generic 401 errors

    @check_device_swap_401.1_no_authorization_header
    Scenario: No Authorization header
        Given the header "Authorization" is removed
        And the request body is set to a valid request body
        When the request "checkDeviceSwap" is sent
        Then the response status code is "401"
        And the response property "$.status" is 401
        And the response property "$.code" is "UNAUTHENTICATED"
        And the response property "$.message" contains a user friendly text

    @check_device_swap_401.2_expired_access_token
    Scenario: Expired access token
        Given the header "Authorization" is set to an expired access token
        And the request body is set to a valid request body
        When the request "checkDeviceSwap" is sent
        Then the response status code is "401"
        And the response property "$.status" is 401
        And the response property "$.code" is "UNAUTHENTICATED"
        And the response property "$.message" contains a user friendly text

    @check_device_swap_401.3_invalid_access_token
    Scenario: Invalid access token
        Given the header "Authorization" is set to an invalid access token
        And the request body is set to a valid request body
        When the request "checkDeviceSwap" is sent
        Then the response status code is "401"
        And the response property "$.status" is 401
        And the response property "$.code" is "UNAUTHENTICATED"
        And the response property "$.message" contains a user friendly text

    # Generic 400 errors

    @check_device_swap_400.1_invalid_phone_number
    Scenario: Check that the response shows an error when the phone number is invalid
        Given the request body property "$.phoneNumber" does not comply with the OAS schema at "/components/schemas/PhoneNumber"
        When the request "checkDeviceSwap" is sent
        Then the response status code is 400
        And the response property "$.status" is 400
        And the response property "$.code" is "INVALID_ARGUMENT"
        And the response property "$.message" contains a user friendly text

    @check_device_swap_400.2_invalid_max_age
    Scenario: Check that the response shows an error when the max age is invalid
        Given the request body property "$.maxAge" does not comply with the OAS schema at "/components/schemas/CreateCheckSimSwap"
        When the request "checkDeviceSwap" is sent
        Then the response status code is 400
        And the response property "$.status" is 400
        And the response property "$.code" is "INVALID_ARGUMENT"
        And the response property "$.message" contains a user friendly text

    @check_device_swap_400.3_out_of_range
    Scenario: Error when maxAge is out of range
        Given the request body property "$.maxAge" is set to a value greater than the allowed range
        When the request "checkDeviceSwap" is sent
        Then the response status code is 400
        And the response property "$.status" is 400
        And the response property "$.code" is "OUT_OF_RANGE"
        And the response property "$.message" contains a user friendly text
