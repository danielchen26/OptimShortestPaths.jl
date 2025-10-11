```@eval
begin
    using Markdown
    dashboard_path = joinpath(dirname(dirname(dirname(@__DIR__))), "examples", "metabolic_pathway", "DASHBOARD.md")
    Markdown.parse(read(dashboard_path, String))
end
```
