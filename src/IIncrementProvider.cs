namespace app;

public interface IIncrementProvider
{
    Task<int> GetIncrementAsync();
}
