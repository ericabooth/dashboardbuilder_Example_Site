# dashboardbuilder — example gallery

Live demo site for [`dashboardbuilder`](https://github.com/ericabooth/dashboardbuilder-stata-public),
a Stata command that builds self-contained, interactive HTML dashboards from your data.

**Live site:** https://ericabooth.github.io/dashboardbuilder_Example_Site/

Each `*.html` here is one self-contained dashboard generated from Stata (open any file, or view
source to see the starter wireframe). `index.html` is the gallery landing page.

## Regenerate

From this folder, in Stata 16+ with `dashboardbuilder` installed:

```stata
do build_site.do
```

That rewrites `auto_quick.html`, `state_explorer.html`, and `lifeexp.html` from datasets that
ship with Stata. The `county_map_dashboard.html` example additionally needs
[`sparkta2`](https://github.com/ericabooth/sparkta2-stata) (it embeds a sparkta2 map via the
`dashboardbuilder panel html` type); `build_site.do` skips it cleanly if sparkta2 is not installed.

## Install dashboardbuilder

```stata
net install dashboardbuilder, from("https://raw.githubusercontent.com/ericabooth/dashboardbuilder-stata-public/main/") replace force
```

© Texas 2036 Data & Research. MIT-licensed.
