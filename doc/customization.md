# Front end customization

Do you want to customize your instance ? Here is a step by step guide.

## Step 1. Understanding

For your information, you can overide any view in our app by replicating the
view structure from `app/views` to `app/custom_views/`.

You can also overide locales by replicating the locales structure from
`config/locales` to `config/custom_locales`.

## Step 2. Customize the views

So let's imagine you want to customize the `app/views/root/_footer.html.haml`.
Here is how to do:

```
$ mkdir app/custom_views/root
$ cp app/views/root/_footer.html.haml app/custom_views/root
```

And _voila!_ You can edit your own template. No need for env var, no need to
worry about conflicts.

## Step 3. Customize the locales

Now let's imagine you want to customize the `config/locales/links.fr.yml`.
Here is how to do:

```
$ cp config/locales/links.fr.yml config/custom_locales
```

And _voila!_ You can now edit your own locales.
