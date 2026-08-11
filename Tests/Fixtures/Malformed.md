# Local Failure Showcase

The following image is missing, but it must not affect later content:

![Missing image](assets/not-found.png)

The following path attempts to escape the document directory and must be blocked:

![Out-of-bounds image](../private.png)

An unknown code language should fall back to plain text:

```made-up-language
unknown instruction 42
```

An invalid formula should affect only its own block:

$$
\frac{1}{
$$

Incomplete *emphasis should remain as readable as possible.

<script>document.body.textContent = 'This must never run.'</script>

Content after the script must remain present.
