<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="utf-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
        <meta name="HandheldFriendly" content="True">
        <meta name="MobileOptimized" content="320">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=0">
        <meta name="theme-color" content="#4c9220">
        <title>{{!headers["title"]}}</title>
        <link rel="shortcut icon" href="/static/favicon.ico">
        <link rel="apple-touch-icon-precomposed" href="http://cdn.ink.sapo.pt/3.1.1/img/touch-icon.57.png">
        <link rel="apple-touch-icon-precomposed" sizes="72x72" href="http://cdn.ink.sapo.pt/3.1.1/img/touch-icon.72.png">
        <link rel="apple-touch-icon-precomposed" sizes="114x114" href="http://cdn.ink.sapo.pt/3.1.1/img/touch-icon.114.png">
        <link rel="apple-touch-startup-image" href="http://cdn.ink.sapo.pt/3.1.1/img/splash.320x460.png" media="screen and (min-device-width: 200px) and (max-device-width: 320px) and (orientation:portrait)">
        <link rel="apple-touch-startup-image" href="http://cdn.ink.sapo.pt/3.1.1/img/splash.768x1004.png" media="screen and (min-device-width: 481px) and (max-device-width: 1024px) and (orientation:portrait)">
        <link rel="apple-touch-startup-image" href="http://cdn.ink.sapo.pt/3.1.1/img/splash.1024x748.png" media="screen and (min-device-width: 481px) and (max-device-width: 1024px) and (orientation:landscape)">

        <!-- load inks css from the cdn -->
        <link rel="stylesheet" type="text/css" href="http://cdn.ink.sapo.pt/3.1.1/css/ink-flex.min.css">
        <link rel="stylesheet" type="text/css" href="http://cdn.ink.sapo.pt/3.1.1/css/font-awesome.min.css">

        <link rel="stylesheet" href="/static/css/syntax.css">
        <link rel="stylesheet" href="/static/css/site.css">
        
        <!-- load inkxs css for IE8 -->
        <!--[if lt IE 9 ]>
            <link rel="stylesheet" href="http://cdn.ink.sapo.pt/3.1.1/css/ink-ie.min.css" type="text/css" media="screen" title="no title" charset="utf-8">
        <![endif]-->

        <!-- test browser flexbox support and load legacy grid if unsupported -->
        <script type="text/javascript" src="http://cdn.ink.sapo.pt/3.1.1/js/modernizr.js"></script>
        <script type="text/javascript">
            Modernizr.load({
              test: Modernizr.flexbox,
              nope : 'http://cdn.ink.sapo.pt/3.1.1/css/ink-legacy.min.css'
            });
        </script>

%if defined('scripts'):
    %for script in scripts:    
        <script src="/static/js/{{script}}"></script>
    %end
%end


    </head>
    <body>
        <!--[if lte IE 9 ]>
        <div class="ink-alert basic" role="alert">
            <button class="ink-dismiss">&times;</button>button>
            <p>
                <strong>You are using an outdated Internet Explorer version.</strong>strong>
                Please <a href="http://browsehappy.com/">upgrade to a modern browser</a>a> to improve your web experience.
            </p>p>
        </div>div>
        -->

        <div id="topbar">
            <!-- Desktop navigation -->
            <nav class="ink-navigation ink-grid ie7">
                <div class="column-group horizontal-gutters">
                    <div class="all-50">
                        <ul class="menu horizontal flat green">
                            <li class="title extralarge"><a href="/">Sushy</a></li>
                        </ul>
                    </div>
                    <div class="all-50 align-right">
                        <form action="/search" class="ink-form pull-right" style="margin-top: 1em;">
                            <div class="column-group">
                                <div class="control-group">
                                    <div class="control append-button" role="search">
                                        <span><input name="q" class="small" type="search"></span>
                                        <button class="ink-button small"><i class="fa fa-search"></i></button>
                                    </div>
                                </div>
                            </div>
                        </form>
                    </div>
                </div>
            </nav>
            <!-- Mobile navigation -->
            <nav class="ink-navigation ink-grid hide-all show-medium show-small">
            </nav>
            <div class="border">
            </div>
        </div>
        </div>
        <!-- TODO: masthead -->

        <!-- TODO: sidebar -->
        <div id="page-content" class="ink-grid content-drawer">
            <div class="page-header">
              <h1 class="slab">{{!headers["title"]}}</h1>
            </div>
            {{!base}}
%include('seealso')
        </div>
        <footer>
            Source on <a href="https://github.com/rcarmo/sushy">Github</a> | Made with <a href="http://ink.sapo.pt">Ink</a>
        </footer>
    </body>
</html>
