# Microsoft Azure API Management .NET REST API Sample

This sample demonstrates how to make calls to the API Management REST API using C# and [the original REST API access model](https://docs.microsoft.com/en-us/rest/api/apimanagement/apimanagementrest/api-management-rest) and demonstrates two ways to generate the access token that lets you make calls to the REST API.

This sample demonstrates the following REST API calls.

-	Get a list of all products - [GET /products](https://docs.microsoft.com/en-us/rest/api/apimanagement/apimanagementrest/azure-api-management-rest-api-product-entity#ListProducts)
-	Get the information for a specific product - [GET /products/{productId}](https://docs.microsoft.com/en-us/rest/api/apimanagement/apimanagementrest/azure-api-management-rest-api-product-entity#GetProduct)
-	List all APIs for a specific product - [GET /products/{productId}/apis](https://docs.microsoft.com/en-us/rest/api/apimanagement/apimanagementrest/azure-api-management-rest-api-product-entity#ListAPIs)
-	Get a list of all APIs - [GET /apis](https://docs.microsoft.com/en-us/rest/api/apimanagement/apimanagementrest/azure-api-management-rest-api-api-entity#ListAPIs)
- Get the details of a specific API - [GET /apis/{apiId}](https://docs.microsoft.com/en-us/rest/api/apimanagement/apimanagementrest/azure-api-management-rest-api-api-entity#GetAPI)
-	Get the details of a specific API - [GET /apis/{apiId} with export=true to include information about the operations.](https://docs.microsoft.com/en-us/rest/api/apimanagement/apimanagementrest/azure-api-management-rest-api-api-entity#GetAPI)

This sample also demonstrates how to generate an access token [programmatically](https://docs.microsoft.com/en-us/rest/api/apimanagement/apimanagementrest/azure-api-management-rest-api-authentication#ProgrammaticallyCreateToken) and in the [publisher portal](https://docs.microsoft.com/en-us/rest/api/apimanagement/apimanagementrest/azure-api-management-rest-api-authentication#ManuallyCreateToken).

There are two ways to run the sample depending on how you want to generate the access token.

## To run the sample using a manually generated access token from the publisher portal

To manually generate the access token from the publisher portal, follow the instructions at [To manually create an access token](https://docs.microsoft.com/en-us/rest/api/apimanagement/apimanagementrest/azure-api-management-rest-api-authentication#ManuallyCreateToken) and paste the token into the following line in `program.cs`.

	static string sharedAccessSignature = "uid=...&ex=...";

If you use this method, then you can comment out the call to `CreateSharedAccessToken` in the subsequent section.

	// To programmatically create the access token so that we can authenticate and call the REST APIs,
	// call this method. If you pasted in the access token from the publisher portal then you can
	// comment out this line.
	// sharedAccessSignature = CreateSharedAccessToken(id, key, expiry);

## To run the sample using a programmatically generated access token

To programmatically generate the access token, follow the instructions at [To programmatically generate an access token](https://docs.microsoft.com/en-us/rest/api/apimanagement/apimanagementrest/azure-api-management-rest-api-authentication#ProgrammaticallyCreateToken) and copy the key and either the primary or secondary key and paste them into the following section in `program.cs`.

	// Programmatically generate the access token used to call the API Management REST API.
	// See "To programmatically create an access token" for instructions on how to get
	// the values for id and key:
	// https://docs.microsoft.com/en-us/rest/api/apimanagement/apimanagementrest/azure-api-management-rest-api-authentication#ProgrammaticallyCreateToken
	// id - the value from the identifier text box in the credentials section of the
	//  API Management REST API tab of the Security section.
	string id = "<your identifier value here>";
	// key - either the primary or secondary key from that same tab.
	string key = "<either the primary or secondary key here>";

## For more information about the API Management REST API
For more information, see [API Management REST API reference](http://aka.ms/smapi).

