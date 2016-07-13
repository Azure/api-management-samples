using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using Microsoft.IdentityModel.Clients.ActiveDirectory;
using System.Net.Http;
using System.Configuration;
using System.Net.Http.Headers;

namespace OAuthDemoClient
{
    public partial class Form1 : Form
    {
        public Form1()
        {
            InitializeComponent();
        }

        private void Form1_Load(object sender, EventArgs e)
        {

        }

        private static string aadInstance = ConfigurationManager.AppSettings["ida:AADInstance"];
        private static string tenant = ConfigurationManager.AppSettings["ida:Tenant"];
        private static string clientId = ConfigurationManager.AppSettings["ida:ClientId"];
        Uri redirectUri = new Uri(ConfigurationManager.AppSettings["ida:RedirectUri"]);

        private static string authority = String.Format(aadInstance, tenant);

        private static string apiResourceId = ConfigurationManager.AppSettings["ApiResourceId"];
        private static string apiBaseAddress = ConfigurationManager.AppSettings["ApiBaseAddress"];

        private AuthenticationContext authContext = null;


        private async void button1_Click_1(object sender, EventArgs e)
        {
            authContext = new AuthenticationContext(authority);

            AuthenticationResult authResult = authContext.AcquireToken(apiResourceId, clientId, redirectUri);

            HttpClient client = new HttpClient();

            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", authResult.AccessToken);

            HttpResponseMessage response = await client.GetAsync(apiBaseAddress + "add?a=1&b=2" + "&subscription-key=xxxxxxxxxxxxxxxxxxxx");

            string responseString = await response.Content.ReadAsStringAsync();

            System.Console.Write(authResult.AccessToken);

            MessageBox.Show(responseString);
        }
    }
}
