Feature: CAMARA Device Swap API, vwip - Operation checkDeviceSwap

  # Input to be provided by the implementation to the tester
  #
  # Testing assets:
  # * A device object which a device swap occurred in the last 240 hours.
  # * for additional testing another device without device swapping last 240 hours.
  # References to OAS spec schemas refer to schemas specifies in device-swap.yaml

  Background: Common checkDeviceSwap setup
    Given the resource "device-swap/vwip/check"
    And the header "Content-Type" is set to "application/json"
    And the header "Authorization" is set to a valid access token
    And the header "x-correlator" complies with the schema at "#/components/schemas/XCorrelator"
    And the request body is set by default to a request body compliant with the schema

  # This first scenario serves as a minimum, not testing any specific verificationResult
  @check_device_swap_1_generic_success_scenario
  Scenario: Common validations for any success scenario
    Given a valid phone number identified by the token or provided in the request body
    When the request "checkDeviceSwap" is sent
    Then the response status code is 200
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response body complies with the OAS schema at "/components/schemas/CheckDeviceSwapInfo"

  # Scenarios testing specific situations

  # For some Operators, the activation date is considered the first device swap event and if it is within the maxAge it is considered a swap
  @check_device_swap_2_valid_device_swap_no_max_age
  Scenario: Check that the response shows that the device has been swapped using default value for maxAge
    Given a valid phone number identified by the token or provided in the request body
    And the device has been swapped in the last 240 hours
    When the request "checkDeviceSwap" is sent
    Then the response status code is 200
    And the value of response property "$.swapped" == true

  # For some Operators, the activation date is considered the first device swap event and if it is within the maxAge it is considered a swap
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
  Scenario: Check that the response shows that the device has not been swapped when "maxAge" is not set and the last swap was more than 240 (default) hours ago
    Given a valid phone number identified by the token or provided in the request body
    And the request body property "maxAge" is not set
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
    And the sim card has been associated with this device for more than "<hours>" hours
    And the request body property "maxAge" is set to a value less than "<hours>" within the allowed range
    When the request "checkDeviceSwap" is sent
    Then the response status code is 200
    And the value of response property "$.swapped" == false

    Examples:
      | hours |
      | 260   |
      | 120   |
      | 24    |
      | 12    |

  @check_device_swap_8_more_than_monitored_period
  Scenario: Check that the response shows that the device has not been swapped when "maxAge" is not set and the last swap was more than outside the monitored period allowed by local regulation
    Given a valid phone number identified by the token or provided in the request body
    And the request body property "maxAge" is not set
    And the device has been swapped outside the monitored period allowed by local regulation
    When the request "checkDeviceSwap" is sent
    Then the response status code is 200
    And the value of response property "$.swapped" == false

  # Specific errors

  # This scenario may not apply if the Operators's implementation does not allow a valid access token to be issued for a phone number that has never been connected to the network and, therefore, cannot reach the API.
  @check_device_swap_422.1_NoDeviceSwapPhoneNumberNeverConnected
  Scenario: Error when the phone number has never connected to the Operators's network so the device has never been activated
    Given a valid phone number provided in the request body
    And the sim for that device has never been connected to the Operator's network
    When the HTTP "POST" request is sent
    Then the response status code is 422
    And the response property "$.status" is 422
    And the response property "$.code" is "SERVICE_NOT_APPLICABLE"
    And the response property "$.message" contains a user friendly text

  # Test cases related to the device identifier

  @check_device_swap_C02_01_phone_number_not_schema_compliant
  Scenario: Phone number value does not comply with the schema
    Given the header "Authorization" is set to a valid access token which does not identify a single phone number
    And the request body property "$.phoneNumber" does not comply with the OAS schema at "/components/schemas/PhoneNumber"
    When the HTTP "POST" request is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  @check_device_swap_C02_02_phone_number_not_found
  Scenario: Phone number not found
    Given the header "Authorization" is set to a valid access token which does not identify a single phone number
    And the request body property "$.phoneNumber" is compliant with the schema but does not identify a valid phone number
    When the HTTP "POST" request is sent
    Then the response status code is 404
    And the response property "$.status" is 404
    And the response property "$.code" is "IDENTIFIER_NOT_FOUND"
    And the response property "$.message" contains a user friendly text

  @check_device_swap_C02_03_unnecessary_phone_number
  Scenario: Phone number not to be included when it can be deduced from the access token
    Given the header "Authorization" is set to a valid access token identifying a phone number
    And  the request body property "$.phoneNumber" is set to a valid phone number
    When the HTTP "POST" request is sent
    Then the response status code is 422
    And the response property "$.status" is 422
    And the response property "$.code" is "UNNECESSARY_IDENTIFIER"
    And the response property "$.message" contains a user friendly text

  @check_device_swap_C02_04_missing_phone_number
  Scenario: Phone number not included and cannot be deducted from the access token
    Given the header "Authorization" is set to a valid access token which does not identify a single phone number
    And the request body property "$.phoneNumber" is not included
    When the HTTP "POST" request is sent
    Then the response status code is 422
    And the response property "$.status" is 422
    And the response property "$.code" is "MISSING_IDENTIFIER"
    And the response property "$.message" contains a user friendly text

  @check_device_swap_C02_05_phone_number_not_supported
  Scenario: Service not available for the phone number
    Given that the service is not available for all phone numbers commercialized by the operator
    And a valid phone number, identified by the token or provided in the request body, for which the service is not applicable
    When the HTTP "POST" request is sent
    Then the response status code is 422
    And the response property "$.status" is 422
    And the response property "$.code" is "SERVICE_NOT_APPLICABLE"
    And the response property "$.message" contains a user friendly text

  # Generic 401 errors

  @check_device_swap_401.1_no_authorization_header
  Scenario: No Authorization header
    Given the header "Authorization" is removed
    And the request body is set to a valid request body
    When the HTTP "POST" request is sent
    Then the response status code is "401"
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text

  @check_device_swap_401.2_expired_access_token
  Scenario: Expired access token
    Given the header "Authorization" is set to an expired access token
    And the request body is set to a valid request body
    When the HTTP "POST" request is sent
    Then the response status code is "401"
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text

  @check_device_swap_401.3_invalid_access_token
  Scenario: Invalid access token
    Given the header "Authorization" is set to an invalid access token
    And the request body is set to a valid request body
    When the HTTP "POST" request is sent
    Then the response status code is "401"
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text

  # Generic 400 errors

  @check_device_swap_400.1_invalid_max_age
  Scenario: Check that the response shows an error when the max age is invalid
    Given the request body property "$.maxAge" does not comply with the OAS schema at "/components/schemas/CreateCheckDeviceSwap"
    When the HTTP "POST" request is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  @check_device_swap_400.2_out_of_range
  Scenario: Error when maxAge is out of range
    Given the request body property "$.maxAge" is set to a value greater than the allowed range
    When the HTTP "POST" request is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "OUT_OF_RANGE"
    And the response property "$.message" contains a user friendly text

  @check_device_swap_400.3_max_age_out_of_monitored_period
  Scenario: Check that the response shows an error when the max age is above the supported monitored period of the API Provider
    # This test only applies if the API Provider has a restricted monitored period by local regulations
    Given the request body property "$.maxAge" is set to a valid value above the supported monitored period of the API Provider
    When the request "checkDeviceSwap" is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "OUT_OF_RANGE"
    And the response property "$.message" contains a user friendly text
