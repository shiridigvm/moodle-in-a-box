# TechCorp Academy Theme Customization

## Overview

The TechCorp theme extends Moodle's Boost theme to create a corporate training platform identity. It uses Boost's SCSS pipeline, so all Boost variables and mixins are available.

## Theme Structure

```
theme/techcorp/
├── config.php              # Theme configuration, layout definitions, SCSS callbacks
├── version.php             # Plugin version and dependencies
├── lib.php                 # SCSS compilation callbacks, file serving
├── lang/en/theme_techcorp.php  # English language strings
├── scss/techcorp.scss      # Main stylesheet
├── templates/
│   ├── columns2.mustache   # Two-column layout (default)
│   └── login.mustache      # Custom login page
├── classes/                # PHP classes (renderers, hooks)
└── pix/                    # Theme images
```

## Changing Brand Colors

Edit the `theme_techcorp_get_pre_scss()` function in `lib.php`:

```php
$pre .= '$primary: #1a365d;' . "\n";      // Navy — navbar, buttons, headings
$pre .= '$secondary: #2b6cb0;' . "\n";    // Blue — accents, hover states
$pre .= '$success: #276749;' . "\n";      // Green — completion, positive actions
$pre .= '$body-bg: #f7fafc;' . "\n";      // Light gray — page background
```

After changing colors, purge caches to recompile SCSS:

```bash
docker compose exec moodle php /var/www/html/admin/cli/purge_caches.php
```

## Modifying the Login Page

The login page uses `templates/login.mustache`. Key customization points:

- **Heading:** Edit the `<h2>` and `<p>` text, or use language strings
- **Background:** Change the gradient in `scss/techcorp.scss` under `#page-login-index`
- **Logo:** Add an `<img>` tag before the heading, referencing a file in `pix/`

## Adding a Custom Font

The theme uses Inter from Google Fonts. To use a self-hosted font:

1. Place font files (`.woff2`) in `theme/techcorp/pix/fonts/`
2. Replace the `@import url(...)` in `techcorp.scss` with `@font-face` declarations
3. Update the `$font-family-sans-serif` variable in `lib.php`

## Layout Customization

The theme defines layouts in `config.php`. Each layout maps to a Mustache template and specifies available block regions. To add a new region:

1. Add the region to the layout definition in `config.php`
2. Add the corresponding block output in the Mustache template
3. Add a language string for the region name

## Testing Changes

```bash
# Lint PHP files
make lint

# Purge caches to see SCSS/template changes
docker compose exec moodle php /var/www/html/admin/cli/purge_caches.php

# Check the theme in the browser
open http://localhost
```

## Creating a Child Theme

To create a variant without modifying TechCorp directly:

1. Copy the `theme/techcorp` directory to `theme/techcorp_variant`
2. Update `config.php`: set `$THEME->name = 'techcorp_variant'` and `$THEME->parents = ['techcorp', 'boost']`
3. Update `version.php` with a new component name
4. Override only the SCSS and templates you need to change
