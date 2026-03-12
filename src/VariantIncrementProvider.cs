using Microsoft.FeatureManagement;

namespace app;

public class VariantIncrementProvider(IVariantFeatureManager featureManager) : IIncrementProvider
{
    public async Task<int> GetIncrementAsync()
    {
        var variant = await featureManager.GetVariantAsync("CounterIncrement", CancellationToken.None);
        return int.TryParse(variant?.Configuration?.Value, out var value) ? value : 1;
    }
}
