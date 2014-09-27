<!DOCTYPE html>
<html>
    <head>
        <meta charset="utf-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
        <title>{{!headers['title']}}</title>
        <meta name="description" content="{{headers['tags'] if "tags" in headers else ""}}">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <link rel="stylesheet" href="/static/css/site.css">
        <link href="http://fonts.googleapis.com/css?family=PT+Serif:400,700,400italic,700italic|Roboto+Slab" rel="stylesheet" type="text/css">
    </head>
    <body class="">
        <div id="page">
            <header role="banner" class="clearfix">
                <h1>{{!headers['title']}}</h1>
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
    <!--<script src="/static/js/debug.js" type="text/javascript"></script>-->
</html>
