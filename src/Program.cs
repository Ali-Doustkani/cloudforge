using app.Components;
using Azure.Identity;
using Microsoft.Extensions.Configuration.AzureAppConfiguration;

var builder = WebApplication.CreateBuilder(args);

builder.Configuration.AddAzureAppConfiguration(options =>
{
    options.Connect(new Uri(builder.Configuration["APP_CONFIG_ENDPOINT"] ?? throw new InvalidOperationException("this env var is required")), new DefaultAzureCredential())
        .Select(KeyFilter.Any, labelFilter: "EN");
});

builder.Services.AddRazorComponents().AddInteractiveServerComponents();
builder.Services.Configure<UiOption>(builder.Configuration.GetSection("UI"));
builder.Services.AddOptionsWithValidateOnStart<UiOption>().ValidateDataAnnotations();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();


app.UseAntiforgery();

app.MapStaticAssets();
app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode();

app.Run();
