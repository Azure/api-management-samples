using Microsoft.Owin;
using Owin;

[assembly: OwinStartupAttribute(typeof(ContosoWebApplication.Startup))]
namespace ContosoWebApplication
{
    public partial class Startup
    {
        public void Configuration(IAppBuilder app)
        {
            ConfigureAuth(app);
        }
    }
}
