# Security Policy

## Supported Version

Security fixes are applied to the latest version on the `main` branch.

## Reporting a Vulnerability

Please do not open a public issue for a suspected vulnerability. Use **Security → Report a vulnerability** in the GitHub repository to submit a private report.

Include the affected file or component, reproduction steps, expected impact, and any suggested mitigation. You should receive an initial response within seven days.

MDReader treats file-system boundary escapes, unsafe HTML execution, unauthorized file modification, and navigation-policy bypasses as security issues.

Relative document resources and bundled application resources are directory-scoped. Explicit absolute image references may point outside the document folder: their contents must pass native raster image identification, have valid image dimensions, and be no larger than 64 MiB. This image-only route does not serve arbitrary local files or allow main-frame navigation. Reading such references is intentional; treat Markdown files referencing private local images with the same care as other local documents.
