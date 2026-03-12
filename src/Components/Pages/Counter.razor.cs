using Microsoft.AspNetCore.Components;

namespace app.Components.Pages;

public partial class Counter
{
    [Inject] private IIncrementProvider IncrementProvider { get; set; } = default!;

    private int currentCount = 0;

    private async Task IncrementCount()
    {
        currentCount += await IncrementProvider.GetIncrementAsync();
    }
}
