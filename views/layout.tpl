<!DOCTYPE html>
<html>
    <head>
        <meta charset="utf-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
        <title>{{title}}</title>
        <meta name="description" content="{{tags}}">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <link rel="stylesheet" href="/static/css/site.css">
        <link href="http://fonts.googleapis.com/css?family=PT+Serif:400,700,400italic,700italic|Roboto+Slab" rel="stylesheet" type="text/css">
    </head>
    <body class="">
        <div id="page">
            <header role="banner" class="clearfix">
                {{!headers['title']}}
            </header>
            <div id="main" class="clearfix">
                <div id="content" class="clearfix">
                    <section id="main-content">
                        {{!base}}
                    </section>
                        <article>
                        </article>
                    </section>
                </div><!-- /content -->
            </div><!-- /main -->
            <footer class="clearfix">
                <p>Powered by <a href="https://github.com/rcarmo/Sushy">sushy</a>.</p>
            </footer>
        </div>
    </body>
</html>
