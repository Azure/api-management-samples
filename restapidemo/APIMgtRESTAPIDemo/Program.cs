using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;

namespace APIMgtRESTAPIDemo
{
    class Program
    {
        // This sample uses the following Nuget packages:
        // Microsoft ASP.NET Web API 2.2 Client Libraries 5.2.3
        // http://www.nuget.org/packages/Microsoft.AspNet.WebApi.Client/
        // Json.NET (automatically installed as a dependency of Microsoft ASP.NET 
        //           Web API 2.2 Client Libraries)
        // http://www.newtonsoft.com/json
        // These packages should be automatically restored when you build the sample.
        // If they are not, enable NuGet Package Restore:
        // http://docs.nuget.org/Consume/Package-Restore

        // api-version query parameter - https://aka.ms/smapi#VersionQueryParameter
        static string apiVersion = "2014-02-14-preview";

        // service name and base url - https://aka.ms/smapi#BaseURL
        static string serviceName = "contoso5";
        static string baseUrl = string.Format("https://{0}.management.azure-api.net", serviceName);

        // You can get an access token from the API Management portal or you can programmatically generate it. For
        // more instructions on both approaches, see http://aka.ms/smapi#Authentication
        // One common cause of 401 Unauthorized response codes is when the Expiry date of the token that was
        // generated in the publisher portal has passed. If that happens, regenerate the token using the directions 
        // in the link above. If you programmatically generate the token this typically does not happen.
        // To use a token generated in the publisher portal, follow the "To manually create an access token" instructions
        // at http://aka.ms/smapi#Authentication and paste in the token using the following format.
        static string sharedAccessSignature = "uid=...&ex=...";
        // To programmatically generate the token, call the CreateSharedAccessToken method below.

        static void Main(string[] args)
        {
            // Programmatically generate the access token used to call the API Management REST API.
            // See "To programmatically create an access token" for instructions on how to get
            // the values for id and key:
            // https://msdn.microsoft.com/library/azure/5b13010a-d202-4af5-aabf-7ebc26800b3d#ProgrammaticallyCreateToken
            // id - the value from the identifier text box in the credentials section of the
            //      API Management REST API tab of the Security section.
            string id = "<your identifier value here>";
            // key - either the primary or secondary key from that same tab.
            string key = "<either the primary or secondary key here>";
            // expiry - the expiration date and time of the generated access token. In this example
            //          the expiry is one day from the time the sample is run.
            DateTime expiry = DateTime.UtcNow.AddDays(1);

            // To programmatically create the access token so that we can authenticate and call the REST APIs,
            // call this method. If you pasted in the access token from the publisher portal then you can
            // comment out this line.
            sharedAccessSignature = CreateSharedAccessToken(id, key, expiry);

            // Get a list of groups and display information about each group - GET /groups
            // https://msdn.microsoft.com/en-us/library/azure/dn776329.aspx#ListGroups
            WorkWithGroups();

            // Get a list of all products - GET /products
            // https://msdn.microsoft.com/en-us/library/azure/dn776336.aspx#ListProducts
            // Iterate the list and gets each individual product - GET /products/{productId}
            // https://msdn.microsoft.com/en-us/library/azure/dn776336.aspx#GetProduct
            // List all APIs for a specific product - GET /products/{productId}/apis
            // https://msdn.microsoft.com/en-us/library/azure/dn776336.aspx#ListAPIs
            WorkWithProducts();

            // Get a list of all APIs - GET /apis
            // https://msdn.microsoft.com/en-us/library/azure/dn781423.aspx#ListAPIs
            // Get the details of a specific API - GET /apis/{apiId}
            // https://msdn.microsoft.com/en-us/library/azure/dn781423.aspx#GetAPI
            // Get the details of a specific API - GET /apis/{apiId}
            // with export=true to include information about the operations.
            // https://msdn.microsoft.com/en-us/library/azure/dn781423.aspx#GetAPI
            WorkWithAPIs();
        }

        #region Helper functions

        // To programmatically create an access token
        // https://msdn.microsoft.com/library/azure/5b13010a-d202-4af5-aabf-7ebc26800b3d#ProgrammaticallyCreateToken
        // Required inputs:
        // id - the value from the identifier text box in the credentials section of the
        //      API Management REST API tab of the Security section.
        // key - either the primary or secondary key from that same tab.
        // expiry - the expiration date and time for the generated access token.
        static private string CreateSharedAccessToken(string id, string key, DateTime expiry)
        {
            using (var encoder = new HMACSHA512(Encoding.UTF8.GetBytes(key)))
            {
                string dataToSign = id + "\n" + expiry.ToString("O", CultureInfo.InvariantCulture);
                string x = string.Format("{0}\n{1}", id, expiry.ToString("O", CultureInfo.InvariantCulture));
                var hash = encoder.ComputeHash(Encoding.UTF8.GetBytes(dataToSign));
                var signature = Convert.ToBase64String(hash);
                string encodedToken = string.Format("uid={0}&ex={1:o}&sn={2}", id, expiry, signature);
                return encodedToken;
            }
        }

        // Format the JSON into an indented multiple line
        // format for display.
        private static string FormatJSON(string json)
        {
            dynamic parsedJson = JsonConvert.DeserializeObject(json);
            return JsonConvert.SerializeObject(parsedJson, Formatting.Indented);
        }

        #endregion

        #region Work with groups

        static private void WorkWithGroups()
        {
            // Get a list of groups and display information about each group - GET /groups
            // https://msdn.microsoft.com/en-us/library/azure/dn776329.aspx#ListGroups
            string groups = GetGroups().Result;

            // Parse the Groups JSON result and display information about the returned groups.
            JObject o = JObject.Parse(groups);

            // How many groups are returned?
            int count = (int)o["value"].Count<object>();
            Console.WriteLine("Groups: {0}", count);

            // Display information about each group.
            for (int i = 0; i < count; i++)
            {
                Console.WriteLine("Group: {0}", i);
                Console.WriteLine("id: {0}", o["value"][i]["id"]);
                Console.WriteLine("name: {0}", o["value"][i]["name"]);
                Console.WriteLine("description: {0}", o["value"][i]["description"]);
                Console.WriteLine("builtIn: {0}", o["value"][i]["builtIn"]);
                Console.WriteLine("type: {0}", o["value"][i]["type"]);
                Console.WriteLine("externalId: {0}", o["value"][i]["externalId"]);
                Console.WriteLine("========================================");
            }
        }

        static async Task<string> GetGroups()
        {
            // Get a list of groups - GET /groups
            // https://msdn.microsoft.com/en-us/library/azure/dn776329.aspx#ListGroups
            string requestUrl = string.Concat(baseUrl, "/groups", "?api-version=", apiVersion);

            using (HttpClient httpClient = new HttpClient())
            {
                var request = new HttpRequestMessage(HttpMethod.Get, requestUrl);

                // Default media type for this operation is application/json, no need to
                // set the accept header.
                // Set the SharedAccessSignature header
                request.Headers.Authorization =
                    new AuthenticationHeaderValue("SharedAccessSignature", sharedAccessSignature);

                // Make the request
                HttpResponseMessage response = await httpClient.SendAsync(request);

                // Throw if there is an error
                response.EnsureSuccessStatusCode();

                string responseBody = await response.Content.ReadAsStringAsync();

                return responseBody;
            }
        }

        #endregion

        #region Work with products

        static void WorkWithProducts()
        {
            // Get a list of all products - GET /products
            // https://msdn.microsoft.com/en-us/library/azure/dn776336.aspx#ListProducts
            string products = GetProducts().Result;

            // For each product, get the groups and APIs that are associated
            // with the product
            JObject o = JObject.Parse(products);

            // How many products are returned?
            int count = (int)o["value"].Count<object>();
            Console.WriteLine("Products: {0}", count);

            // Retrieve information about each product.
            for (int i = 0; i < count; i++)
            {
                // This returns the format /products/2bc3baae-1bfc-4c0e-a1ab-7e76c88dfa79
                string id = (string)o["value"][i]["id"];

                // Get just the guid part, used for subsequent calls
                string productId = id.Substring(id.Length - 24);

                // Gets the details of a specific product - GET /products/{productId}
                // https://msdn.microsoft.com/en-us/library/azure/dn776336.aspx#GetProduct
                // Note that this information is also present in GET /products
                // but for demonstration purposes we call both.
                string product = GetProduct(productId).Result;
                Console.WriteLine("Product {0} - {1}:", productId, o["value"][i]["name"]);
                Console.WriteLine(FormatJSON(product));

                // List all APIs for that product - GET /products/{productId}/apis
                // https://msdn.microsoft.com/en-us/library/azure/dn776336.aspx#ListAPIs
                string apis = GetProductAPIs(productId).Result;
                Console.WriteLine("APIs:");
                Console.WriteLine(FormatJSON(apis));
            }
        }

        static async Task<string> GetProducts()
        {
            // Call the GET /products operation
            // https://msdn.microsoft.com/en-us/library/azure/dn776336.aspx#ListProducts
            string requestUrl = string.Concat(baseUrl, "/products", "?api-version=", apiVersion);

            using (HttpClient httpClient = new HttpClient())
            {
                var request = new HttpRequestMessage(HttpMethod.Get, requestUrl);

                // Default media type for this operation is application/json, no need to
                // set the accept header.
                // Set the SharedAccessSignature header
                request.Headers.Authorization =
                    new AuthenticationHeaderValue("SharedAccessSignature", sharedAccessSignature);

                // Make the request
                HttpResponseMessage response = await httpClient.SendAsync(request);

                // Throw if there is an error
                response.EnsureSuccessStatusCode();

                string responseBody = await response.Content.ReadAsStringAsync();

                return responseBody;
            }
        }


        static async Task<string> GetProduct(string productId)
        {
            // Call GET /products/{productId}
            // https://msdn.microsoft.com/en-us/library/azure/dn776336.aspx#GetProduct
            string requestUrl = string.Format("{0}/products/{1}?api-version={2}", baseUrl, productId, apiVersion);

            using (HttpClient httpClient = new HttpClient())
            {
                var request = new HttpRequestMessage(HttpMethod.Get, requestUrl);

                // Default media type for this operation is application/json, no need to
                // set the accept header.

                // Set the SharedAccessSignature header
                request.Headers.Authorization =
                    new AuthenticationHeaderValue("SharedAccessSignature", sharedAccessSignature);

                // Make the request
                HttpResponseMessage response = await httpClient.SendAsync(request);

                // Throw if there is an error
                response.EnsureSuccessStatusCode();

                string responseBody = await response.Content.ReadAsStringAsync();

                return responseBody;
            }
        }

        static async Task<string> GetProductAPIs(string productId)
        {
            // Call GET /products/{productId}/apis
            // https://msdn.microsoft.com/en-us/library/azure/dn776336.aspx#ListAPIs
            string requestUrl = string.Format("{0}/products/{1}/apis?api-version={2}", baseUrl, productId, apiVersion);

            using (HttpClient httpClient = new HttpClient())
            {
                var request = new HttpRequestMessage(HttpMethod.Get, requestUrl);

                // Default media type for this operation is application/json, no need to
                // set the accept header.

                // Set the SharedAccessSignature header
                request.Headers.Authorization =
                    new AuthenticationHeaderValue("SharedAccessSignature", sharedAccessSignature);

                // Make the request
                HttpResponseMessage response = await httpClient.SendAsync(request);

                // Throw if there is an error
                response.EnsureSuccessStatusCode();

                string responseBody = await response.Content.ReadAsStringAsync();

                return responseBody;
            }

        }
        #endregion

        #region Work with APIs

        static void WorkWithAPIs()
        {
            // Get a list of all APIs - GET /apis
            // https://msdn.microsoft.com/en-us/library/azure/dn781423.aspx#ListAPIs
            string apis = GetAPIs().Result;

            // Parse the APIs JSON result and display information about the returned APIs.
            JObject o = JObject.Parse(apis);

            // How many apis are returned?
            int count = (int)o["value"].Count<object>();
            Console.WriteLine("APIs: {0}", count);

            // Display the results of the call to GetAPIs
            Console.WriteLine(FormatJSON(apis));

            // Retrieve information about each API. There is overlap between these results
            // and the results of the call to GetAPIs; we show both here for demo purposes.
            for (int i = 0; i < count; i++)
            {
                // This returns the format /apis/2bc3baae-1bfc-4c0e-a1ab-7e76c88dfa79
                string id = (string)o["value"][i]["id"];

                // Get just the guid part, used for subsequent calls.
                string apiId = id.Substring(id.Length - 24);

                // Gets the details of a specific API - GET /apis/{apiId}
                // https://msdn.microsoft.com/en-us/library/azure/dn781423.aspx#GetAPI
                // Note that this information is also present in GET /apis
                // but for demonstration purposes we call both.
                string api = GetAPI(apiId).Result;
                Console.WriteLine("API {0} - {1}:", apiId, o["value"][i]["name"]);
                Console.WriteLine(FormatJSON(api));

                // Gets the details of a specific API - GET /apis/{apiId}
                // with export=true to include information about the operations.
                // https://msdn.microsoft.com/en-us/library/azure/dn781423.aspx#GetAPI
                // Note that this information is also present in GET /apis
                // but for demonstration purposes we call both.
                api = GetAPIExportJson(apiId).Result;
                Console.WriteLine("API with exported JSON:");
                Console.WriteLine(FormatJSON(api));
            }
        }

        static async Task<string> GetAPIs()
        {
            // Call the GET /apis operation
            // https://msdn.microsoft.com/en-us/library/azure/dn781423.aspx#ListAPIs
            string requestUrl = string.Concat(baseUrl, "/apis", "?api-version=", apiVersion);

            using (HttpClient httpClient = new HttpClient())
            {
                var request = new HttpRequestMessage(HttpMethod.Get, requestUrl);

                // Default media type for this operation is application/json, no need to
                // set the accept header.

                // Set the SharedAccessSignature header
                request.Headers.Authorization =
                    new AuthenticationHeaderValue("SharedAccessSignature", sharedAccessSignature);

                // Make the request
                HttpResponseMessage response = await httpClient.SendAsync(request);

                // Throw if there is an error
                response.EnsureSuccessStatusCode();

                string responseBody = await response.Content.ReadAsStringAsync();

                return responseBody;
            }
        }

        static async Task<string> GetAPI(string apiId)
        {
            // Call the GET /apis/{apiId} operation
            // https://msdn.microsoft.com/en-us/library/azure/dn781423.aspx#GetAPI
            string requestUrl = string.Format("{0}/apis/{1}?api-version={2}", baseUrl, apiId, apiVersion);

            using (HttpClient httpClient = new HttpClient())
            {
                var request = new HttpRequestMessage(HttpMethod.Get, requestUrl);

                // Set the SharedAccessSignature header
                request.Headers.Authorization =
                    new AuthenticationHeaderValue("SharedAccessSignature", sharedAccessSignature);

                // Content Type header not required since default is application/json, no need to
                // set accept header

                // Make the request
                HttpResponseMessage response = await httpClient.SendAsync(request);

                // Throw if there is an error
                response.EnsureSuccessStatusCode();

                string responseBody = await response.Content.ReadAsStringAsync();

                return responseBody;
            }
        }

        static async Task<string> GetAPIExportJson(string apiId)
        {
            // Call the GET /apis/{apiId} operation with export=true
            // https://msdn.microsoft.com/en-us/library/azure/dn781423.aspx#ListAPIs
            string requestUrl = string.Format("{0}/apis/{1}?api-version={2}&export=true", baseUrl, apiId, apiVersion);

            using (HttpClient httpClient = new HttpClient())
            {
                var request = new HttpRequestMessage(HttpMethod.Get, requestUrl);

                // Set the SharedAccessSignature header
                request.Headers.Authorization =
                    new AuthenticationHeaderValue("SharedAccessSignature", sharedAccessSignature);

                // Content Type header is required when export=true
                // See GET /apis/{apiId} documentation for export type values.
                request.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));

                // Make the request
                HttpResponseMessage response = await httpClient.SendAsync(request);

                // Throw if there is an error
                response.EnsureSuccessStatusCode();

                string responseBody = await response.Content.ReadAsStringAsync();

                return responseBody;
            }
        }

        #endregion
    }
}
