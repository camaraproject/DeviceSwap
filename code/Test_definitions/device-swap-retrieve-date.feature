Feature: CAMARA Device Swap API, 0.2.0 - Operation retrieveDeviceSwapDate

  # Input to be provided by the implementation to the tester
  #
  # Testing assets:
  #
  # References to OAS spec schemas refer to schemas specifies in device-swap.yaml, version 0.2.0
  #
  # Get timestamp of last device swap for a mobile user account provided with phone number.

    Background: Common retrieveDeviceSwapDate setup
        Given the resource "device-swap/v0.2/retrieve-date"
        And the header "Content-Type" is set to "application/json"
        And the header "Authorization" is set to a valid access token
        And the header "x-correlator" complies with the schema at "#/components/schemas/XCorrelator"
        And the request body is set by default to a request body compliant with the schema

    # This first scenario serves as a minimum, not testing any specific verificationResult
    @retrieve_device_swap_date_1_generic_success_scenario
    Scenario: Common validations for any sucess scenario
        Given a valid phone number identified by the token or provided in the request body
        When the request "retrieveDeviceSwapDate" is sent
        Then the response status code is 200
        And the response header "Content-Type" is "application/json"
        And the response header "x-correlator" has same value as the request header "x-correlator"
        And the response body complies with the OAS schema at "/components/schemas/DeviceSwapInfo"

    # Scenarios testing specific situations

    @retrieve_device_swap_date_2_valid_device_swap
    Scenario: Retrieve decive swap date for a valid device swap
        Given a valid phone number identified by the token or provided in the request body
        And the device has been swapped
        When the request "retrieveDeviceSwapDate" is sent
        Then the response status code is 200
        And the response property "$.latestDeviceChange" contains a valid timestamp

    # This scenario applies for operators which do not limit the "monitoring history"
    @retrieve_device_swap_date_3_no_device_swap_returns_activation_date
    Scenario: Response contains the first time that the SIM is installed in the device when it hasn't been swapped
        Given a valid phone number identified by the token or provided in the request body
        And the device has never been swapped
        When the request "retrieveDeviceSwapDate" is sent
        Then the response status code is 200
        And the response property "$.latestDeviceChange" contains the timestamp of the first time that the SIM is installed in the device


    # This scenario applies when there is a local regulation with a time limitation on the information that can be returned
    @retrieve_device_swap_date_4_no_device_swap_or_activation_date_due_to_legal_constrain
    Scenario: Retrieves device swap empty for a valid device swap when exists local regulations
        Given a valid phone number identified by the token or provided in the request body
        And the last device swap occurred outside the monitoring period allowed by local regulation
        When the request "retrieveDeviceSwapDate" is sent
        Then the response status code is 200
        And the response property "$.latestDeviceChange" is null

    # Specific errors

    # This test applies if the operator allows to do the request for a sim that has never been connected to the network
    @retrieve_device_swap_date_5_not_activated
    Scenario: Error device swap date for a non-activated sim
        Given a valid phone number provided in the request body
        And the sim for that device has never been connected to the Operator's network
        When the HTTP "POST" request is sent
        Then the response status code is 422
        And the response property "$.status" is 422
        And the response property "$.code" is "NOT_SUPPORTED"
        And the response property "$.message" contains a user friendly text

    # Test cases related to the device identifier

    @retrieve_device_swap_date_6_C02_01_phone_number_not_schema_compliant
    Scenario: Phone number value does not comply with the schema
        Given the header "Authorization" is set to a valid access token which does not identify a single phone number
        And the request body property "$.phoneNumber" does not comply with the OAS schema at "/components/schemas/PhoneNumber"
        When the HTTP "POST" request is sent
        Then the response status code is 400
        And the response property "$.status" is 400
        And the response property "$.code" is "INVALID_ARGUMENT"
        And the response property "$.message" contains a user friendly text

    @retrieve_device_swap_date_7_C02_02_phone_number_not_found
    Scenario: Phone number not found
        Given the header "Authorization" is set to a valid access token which does not identify a single phone number
        And the request body property "$.phoneNumber" is compliant with the schema but does not identify a valid phone number
        When the HTTP "POST" request is sent
        Then the response status code is 404
        And the response property "$.status" is 404
        And the response property "$.code" is "IDENTIFIER_NOT_FOUND"
        And the response property "$.message" contains a user friendly text

    @retrieve_device_swap_date_8_C02_03_unnecessary_phone_number
    Scenario: Phone number not to be included when it can be deduced from the access token
        Given the header "Authorization" is set to a valid access token identifying a phone number
        And  the request body property "$.phoneNumber" is set to a valid phone number
        When the HTTP "POST" request is sent
        Then the response status code is 422
        And the response property "$.status" is 422
        And the response property "$.code" is "UNNECESSARY_IDENTIFIER"
        And the response property "$.message" contains a user friendly text

    @check_device_swap_9_C02_04_missing_phone_number
    Scenario: Phone number not included and cannot be deducted from the access token
        Given the header "Authorization" is set to a valid access token which does not identify a single phone number
        And the request body property "$.phoneNumber" is not included
        When the HTTP "POST" request is sent
        Then the response status code is 422
        And the response property "$.status" is 422
        And the response property "$.code" is "MISSING_IDENTIFIER"
        And the response property "$.message" contains a user friendly text

    @retrieve_device_swap_date_10_C02_05_phone_number_not_supported
    Scenario: Service not available for the phone number
        Given that the service is not available for all phone numbers commercialized by the operator
        And a valid phone number, identified by the token or provided in the request body, for which the service is not applicable
        When the HTTP "POST" request is sent
        Then the response status code is 422
        And the response property "$.status" is 422
        And the response property "$.code" is "SERVICE_NOT_APPLICABLE"
        And the response property "$.message" contains a user friendly text

    # Generic 401 errors

    @retrieve_device_swap_date_401.1_no_authorization_header
    Scenario: No Authorization header
        Given the header "Authorization" is removed
        And the request body is set to a valid request body
        When the HTTP "POST" request is sent
        Then the response status code is 401
        And the response property "$.status" is 401
        And the response property "$.code" is "UNAUTHENTICATED"
        And the response property "$.message" contains a user friendly text

    @retrieve_device_swap_date_401.2_expired_access_token
    Scenario: Expired access token
        Given the header "Authorization" is set to an expired access token
        And the request body is set to a valid request body
        When the HTTP "POST" request is sent
        Then the response status code is 401
        And the response property "$.status" is 401
        And the response property "$.code" is "UNAUTHENTICATED"
        And the response property "$.message" contains a user friendly text

    @retrieve_device_swap_date_401.3_invalid_access_token
    Scenario: Invalid access token
        Given the header "Authorization" is set to an invalid access token
        And the request body is set to a valid request body
        When the HTTP "POST" request is sent
        Then the response status code is 401
        And the response property "$.status" is 401
        And the response property "$.code" is "UNAUTHENTICATED"
        And the response property "$.message" contains a user friendly text
