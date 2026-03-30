using Microsoft.AspNetCore.Components;

namespace app.Components.Pages;

public partial class Counter
{
    private int currentCount = 0;

    private void IncrementCount()
    {
        currentCount += 1;
    }
}
