<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="utf-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
        <meta name="HandheldFriendly" content="True">
        <meta name="MobileOptimized" content="320">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=0">
        <meta name="theme-color" content="#ffffff">
        <title>{{!headers["title"]}}</title>
        <link rel="shortcut icon" href="/static/favicon.ico">
        <link rel="search" type="application/opensearchdescription+xml" title="{{site_name}}" href="/opensearch.xml"/>
        <link href="//fonts.googleapis.com/css?family=Raleway:400,300,600" rel="stylesheet" type="text/css">
        <link rel="stylesheet" href="/static/css/normalize.css">
        <link rel="stylesheet" href="/static/css/skeleton.css">
        <link rel="stylesheet" href="/static/css/custom.css">
        <link rel="stylesheet" href="/static/css/syntax.css">

%if defined('scripts'):
    %for script in scripts:    
        <script src="/static/js/{{script}}"></script>
    %end
%end

    </head>
    <body>
        <div class="container topbar">
            <div class="row">
                <div class="nine columns">
                    <a href="/space"><h1>Sushy</h1></a>
                </div>
                <div class="three columns">
                    <form action="/search">
                        <input id="q" name="q" class="small" type="search" placeholder="Search">
                    </form>
                </div>
            </div>
        </div>
        {{!base}}
        <footer class="container">
            <div class="row">
                <div class="six columns">
                Powered by <a href="https://github.com/rcarmo/sushy">Sushy</a>, designed with <a href="http://getskeleton.com">Skeleton</a>
                </div>
            </div>
        </footer>
    </body>
</html>