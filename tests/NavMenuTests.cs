using Bunit;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.FeatureManagement;
using Moq;
using Xunit;
using app.Components.Layout;

namespace app.Tests;

public class NavMenuTests : BunitContext
{
    [Fact]
    public void WeatherLink_WhenFeatureFlagEnabled_IsVisible()
    {
        var featureManager = new Mock<IFeatureManager>();
        featureManager.Setup(m => m.IsEnabledAsync("enable_weather")).ReturnsAsync(true);
        Services.AddSingleton(featureManager.Object);

        var cut = Render<NavMenu>();

        Assert.NotEmpty(cut.FindAll("a[href='weather']"));
    }

    [Fact]
    public void WeatherLink_WhenFeatureFlagDisabled_IsHidden()
    {
        var featureManager = new Mock<IFeatureManager>();
        featureManager.Setup(m => m.IsEnabledAsync("enable_weather")).ReturnsAsync(false);
        Services.AddSingleton(featureManager.Object);

        var cut = Render<NavMenu>();

        Assert.Empty(cut.FindAll("a[href='weather']"));
    }
}
