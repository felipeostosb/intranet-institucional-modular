namespace Intranet.Core.Common;

public class PagedResult<T>
{
    public List<T> Items { get; set; } = new();
    public int CurrentPage { get; set; } = 1;
    public int PageSize { get; set; } = 10;
    public int TotalItems { get; set; }
    public int TotalPages => (int)Math.Ceiling((double)TotalItems / PageSize);
    public bool HasPreviousPage => CurrentPage > 1;
    public bool HasNextPage => CurrentPage < TotalPages;

    public PagedResult() { }

    public PagedResult(List<T> items, int count, int pageIndex, int pageSize)
    {
        Items = items;
        TotalItems = count;
        CurrentPage = pageIndex;
        PageSize = pageSize;
    }
}
