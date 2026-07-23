# Vendor files

This folder contains vendored third-party assets for offline use.

## Required file

- `xlsx.full.min.js`

## What to download

Download the SheetJS Community Edition browser bundle named `xlsx.full.min.js`.

Specifically:

1. Go to the SheetJS GitHub repository: https://github.com/SheetJS/sheetjs
2. Find the release or documentation for the Community Edition.
3. Download the browser bundle file named `xlsx.full.min.js`.

## Where to place it

Put the downloaded file in this folder:

- `vendor/xlsx.full.min.js`

Then the dashboard can load it offline using the relative path:

```html
<script src="vendor/xlsx.full.min.js"></script>
```
