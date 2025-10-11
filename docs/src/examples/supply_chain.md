```@eval
begin
    using Markdown
    dashboard_path = joinpath(dirname(dirname(dirname(@__DIR__))), "examples", "supply_chain", "DASHBOARD.md")
    Markdown.parse(read(dashboard_path, String))
end
```
