<!DOCTYPE html>
<html lang="en">
    <head>
        <title>{{!headers["title"]}} - {{!site_name}}</title>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
        <meta name="HandheldFriendly" content="True">
        <meta name="MobileOptimized" content="320">
        <meta name="viewport" content="width=device-width">
        <meta name="theme-color" content="#ffffff">
        <meta name="description" content="{{!site_description}}">
        <meta name="generator" content="Sushy">
        <meta name="robots" content="index,follow">
%if "tags" in headers:        
        <meta name="keywords" content="{{!headers["tags"]}}">
%end        
        <link rel="shortcut icon" href="/favicon.ico">
        <link rel="apple-touch-icon" href="/apple-touch-icon-precomposed.png">
        <link rel="alternate" type="application/atom+xml" title="{{site_name}}" href="/feed"/>
        <link rel="search" type="application/opensearchdescription+xml" title="{{site_name}}" href="/opensearch.xml"/>
%if True:
        <link rel="stylesheet" href="/static/css/bundle-20160530.css">
%else:
        <link rel="stylesheet" href="/static/css/poole.css">
        <link rel="stylesheet" href="/static/css/lanyon.css">
        <link rel="stylesheet" href="/static/css/custom.css">
        <link rel="stylesheet" href="/static/css/syntax.css">
%end
%include('custom_meta', **globals())
%if True:
        <script async src="/static/js/bundle-20160508.js"></script>
%elif defined('scripts'):
    %for script in scripts:    
        <script src="/static/js/{{script}}"></script>
    %end
%end
        <script type="application/ld+json">
            {"@context": "http://schema.org",
             "@type": "WebSite",
             "name": "{{!site_name}}", 
             "alternateName": "{{!site_description}}",
             "url": "{{!base_url}}"}
        </script>
    </head>
    <body class="layout-reverse">
        %include('sidebar', **globals())
        <div class="wrap">
            <div class="masthead">
                <div class="container">
                    <h3 class="masthead-title">
                        <a href="/" title="">
                        <img class="logo" src="/apple-touch-icon.png" width="36" height="36">{{!site_name}}</a>
                    </h3>
                </div>
            </div>
            %include('custom_ads', **globals())
            {{!base}}
        </div>
        <label for="sidebar-checkbox" class="sidebar-toggle"></label>
        <!-- TODO: edit sidebar, fat footer template -->
        <footer>
        %include('custom_footer', **globals())
        </footer>
    </body>
</html>
