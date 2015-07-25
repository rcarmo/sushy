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
        <!--
            <link href="//fonts.googleapis.com/css?family=Raleway:400,300,600" rel="stylesheet" type="text/css">
        -->
        <link rel="stylesheet" href="/static/css/poole.css">
        <link rel="stylesheet" href="/static/css/lanyon.css">
        <link rel="stylesheet" href="/static/css/rss.css">
        <link rel="stylesheet" href="/static/css/custom.css">
        <link rel="stylesheet" href="/static/css/syntax.css">

%if defined('scripts'):
    %for script in scripts:    
        <script src="/static/js/{{script}}"></script>
    %end
%end

    </head>
    <body class="layout-reverse">
        %include('sidebar')
        <div class="wrap">
            <div class="masthead">
                <div class="container">
                    <h3 class="masthead-title">
                        <a href="/" title="">Sushy</a>
                    </h3>
                </div>
            </div>
            
            {{!base}}
            <hr>
            <footer class="container">
                Powered by <a href="https://github.com/rcarmo/sushy">Sushy</a>.                    </div>
            </footer>
        </div>
        <label for="sidebar-checkbox" class="sidebar-toggle"></label>
    </body>
</html>