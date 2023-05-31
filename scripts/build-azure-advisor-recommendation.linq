<Query Kind="Program">
  <Reference>&lt;RuntimeDirectory&gt;\System.Runtime.Serialization.dll</Reference>
  <Reference>&lt;RuntimeDirectory&gt;\System.Runtime.Serialization.Primitives.dll</Reference>
  <NuGetReference>Newtonsoft.Json</NuGetReference>
  <Namespace>System.Runtime.Serialization</Namespace>
  <Namespace>Newtonsoft.Json</Namespace>
</Query>

const string RecommendationPath = @"<repo>\Azure\SelfHelpContent\articles\advisorrecommendation.apimanagement";

void Main()
{
	var actionId = Guid.NewGuid();
	var typeId = Guid.NewGuid();
	var friendlyName = Prompt("Friendly name");
	var category = Prompt("Category", "HighAvailability", "Cost", "Performance");
	var impact = Prompt("Impact", "High", "Medium", "Low");
	var label = Prompt("Label");
	var longDescription = Prompt("Long description");
	var benefits = Prompt("Potential benefits");
	var link = Prompt("Learn more link");
	var kustoFunction = Prompt("Kusto function name");
	
	foreach(var env in Environments.Keys)
	{
		var suffix = env == "public" ? string.Empty : $"_{env}";
		File.WriteAllText(Path.Combine(RecommendationPath, $"{friendlyName}{suffix}.md"), GetRecommendation(env, typeId, actionId, friendlyName, category, impact, link, longDescription, benefits, label, kustoFunction));
	}
}

string Prompt(string message, params string[] options)
{
	Console.Write($"{message}");
	Console.Write(options?.Length > 0
		? $" ({string.Join("|", options)}): "
		: ": ");

	var result = Console.ReadLine();
	if (options?.Length > 0)
	{
		result = options.FirstOrDefault(o => o.StartsWith(result, StringComparison.InvariantCultureIgnoreCase));
	}

	result = string.IsNullOrWhiteSpace(result)
		? null
		: result.Trim();

	Console.WriteLine(result);
	
	return result;
}

Dictionary<string, Dictionary<string, string>> Environments = new Dictionary<string, System.Collections.Generic.Dictionary<string, string>>
{
	["public"] = new Dictionary<string, string>{
		["cloudEnvironments"] = "Public, USSec, USNat",
		["KustoAddress"] = "cluster('https://apim.kusto.windows.net').database('APIMProd')"
	},
	["ussec"] = new Dictionary<string, string>
	{
		["cloudEnvironments"] = "USSec",
		["KustoAddress"] = "cluster('https://apimussec.usseceast.kusto.core.microsoft.scloud').database('APIMUSSEC')"
	},
	["usnat"] = new Dictionary<string, string>
	{
		["cloudEnvironments"] = "USNat",
		["KustoAddress"] = "cluster('https://apimusnat.usnateast.kusto.core.eaglex.ic.gov').database('APIMUSNat')"
	},
	["mooncake"] = new Dictionary<string, string>
	{
		["cloudEnvironments"] = "Mooncake",
		["KustoAddress"] = "cluster('https://apimchina.kusto.chinacloudapi.cn').database('APIMChina')"
	},
	["fairfax"] = new Dictionary<string, string>
	{
		["cloudEnvironments"] = "Fairfax",
		["KustoAddress"] = "cluster('https://apimusgov.kusto.usgovcloudapi.net').database('APIMUSGov')"
	}
};

string GetRecommendation(
	string envId,
	Guid typeId,
	Guid actionId,
	string friendlyName,
	string category,
	string impact,
	string link,
	string longDescription,
	string benefits,
	string label,
	string kustoFunction
	)
{
	var env = Environments[envId];

	return $@"<properties
    pageTitle=""{label}.""
    description=""{label}.""
    authors=""apicore""
    ms.author=""aoapicoreaft""
    articleId=""{Guid.NewGuid().ToString("D")}_{env["cloudEnvironments"].Split(",").First()}""
    selfHelpType=""advisorRecommendationMetadata""
    cloudEnvironments=""{env["cloudEnvironments"]}""
    ownershipId=""Compute_APIManagement""
/>
---
{{
  ""$schema"": ""AdvisorRecommendation"",
  ""version"": 1.0,
  ""recommendationOfferingId"": ""7e1fb574-eb4a-45d7-8db2-c85445aac53f"",
  ""recommendationOfferingName"": ""Azure API Management"",
  ""recommendationResourceType"": ""Microsoft.ApiManagement/service"",
  ""recommendationMetadataState"": ""Active"",
  ""owner"": {{
    ""email"": ""apicore@microsoft.com"",
    ""icm"": {{
      ""routingId"": ""mdm://adspartner/apimanage/serviceloop"",
      ""service"": ""API Management"",
      ""team"": ""ServicingLoop""
    }},
    ""serviceTreeId"": ""6ba70dfa-ead9-4cc1-b894-049f8a17c22b""
  }},
  ""resourceMetadata"": {{
    ""action"": {{
      ""actionId"": ""72430dca-3844-4a48-8e6c-8711df8e0e6f"",
      ""actionType"": ""Blade"",
      ""extensionName"": ""HubsExtension"",
      ""bladeName"": ""ResourceMenuBlade"",
      ""metadata"": {{
        ""id"": ""{{resourceId}}""
      }}
    }}
  }},

  ""recommendationTypeId"": ""{typeId.ToString("D")}"",
  ""recommendationCategory"": ""{category}"",
  ""recommendationImpact"": ""{impact}"",
  ""recommendationFriendlyName"": ""{friendlyName}"",
  ""learnMoreLink"": ""{link}"",
  ""description"": ""{label}"",
  ""longDescription"": {JsonConvert.ToString(longDescription)},
  ""potentialBenefits"": ""{benefits}"",
  ""displayLabel"": ""{label}"",
  ""additionalColumns"": [
    ...
  ],
  ""actions"": [
    ""actionId"": ""{typeId.ToString("D")}"",
	""description"": ""..."",
	""actionType"": ""ContextBlade|Blade|Document""
	...
  ],
  ""dataSourceMetadata"": {{
    ""streamNamespace"": ""{env["KustoAddress"]}.{kustoFunction}"",
    ""dataSource"": ""Kusto"",
    ""refreshInterval"": ""0.08:00:00""
  }}
}}
---
";
}