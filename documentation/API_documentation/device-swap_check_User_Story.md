# Device Swap Check API User Story


| **Item** | **Details** |
| ---- | ------- |
| ***Summary*** | As an enterprise application developer, I want to check if a device swap has occurred within a specified period for a user's mobile number so that I can enhance security measures against account takeover fraud.  |
| ***Actors and Scope*** | **Actors:** Application service provider (ASP), ASP:User, ASP: BusinessManager, ASP:Administrator, Channel Partner, End-User, Communication Service Provider (CSP). <br>**Scope:**  <br> - Checks if a device swap has occurred within a specified period for a given phone number. |
| ***Pre-conditions*** |The preconditions are listed below:<br><ol><li>The ASP:BusinessManager and ASP:Administrator have been onboarded to the CSP's API platform via (or not) a Channel Partner.</li><li>The ASP:BusinessManager has successfully subscribed to the Device Swap API product from the CSP's product catalog via (or not) a Channel Partner.</li><li>The ASP:Administrator has onboarded the ASP:User to the platform.</li><li>The ASP:User performs an authorization request to CSP</li><li> The CSP checks access & End-User approval then provide access token to the ASP:User </li><li>The ASP:User get the access token, via (or not) the Channel Partner, allowing a secure access of the API.|
| ***Activities/Steps*** | **Starts when:** The ASP:User makes a POST request via the Device Swap API, providing the phone number and the desired period to check for device swaps. This request could be done via (or not) the Channel Partner.<br>**Ends when:** The CSP's Device Swap server responds indicating whether a Device Swap has been performed within the specified period. |
| ***Post-conditions*** | The ASP:User could continue offering its service to the End-User with the confirmation of the validity of the End-User's line, based on the Device Swap information.  |
| ***Exceptions*** | Several exceptions might occur during the Device Swap API operations<br>- Unauthorized: Not valid credentials (e.g., use of already expired access token).<br>- Invalid input: Not valid input data to invoke operation (e.g., improperly formatted phone number).|
