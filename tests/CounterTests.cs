using Bunit;
using Microsoft.Extensions.DependencyInjection;
using Moq;
using Xunit;
using app;
using app.Components.Pages;

namespace app.Tests;

public class CounterTests : BunitContext
{
    private void SetupIncrement(int increment)
    {
        var provider = new Mock<IIncrementProvider>();
        provider.Setup(p => p.GetIncrementAsync()).ReturnsAsync(increment);
        Services.AddSingleton(provider.Object);
    }

    [Fact]
    public void IncrementCount_WhenControlVariant_IncrementsBy1()
    {
        SetupIncrement(1);
        var cut = Render<Counter>();

        cut.Find("button").Click();

        Assert.Contains("Current count: 1", cut.Find("[role='status']").TextContent);
    }

    [Fact]
    public void IncrementCount_WhenTreatmentVariant_IncrementsBy5()
    {
        SetupIncrement(5);
        var cut = Render<Counter>();

        cut.Find("button").Click();

        Assert.Contains("Current count: 5", cut.Find("[role='status']").TextContent);
    }
}
