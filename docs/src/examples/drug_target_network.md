```@eval
begin
    using Markdown
    dashboard_path = joinpath(dirname(dirname(dirname(@__DIR__))), "examples", "drug_target_network", "DASHBOARD.md")
    Markdown.parse(read(dashboard_path, String))
end
```
